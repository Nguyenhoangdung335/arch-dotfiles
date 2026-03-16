use std::sync::Arc;

use tokio::net::UnixListener;

use crate::app::AppContext;
use crate::config;
use crate::ipc::handler;

pub async fn start(ctx: Arc<AppContext>) -> anyhow::Result<()> {
    let socket_path = ctx.config().await.server.socket_path.clone();
    let socket_path = config::socket_path(&socket_path);

    if let Some(parent) = socket_path.parent() {
        tokio::fs::create_dir_all(parent).await?;
    }
    if socket_path.exists() {
        tokio::fs::remove_file(&socket_path).await.map_err(|e| {
            eprintln!("Failed to remove old socket: {}", e);
            e
        })?;
    }
    let listener = UnixListener::bind(&socket_path)?;
    set_socket_permissions(&socket_path)?;
    println!("IPC server listening on {:?}", socket_path);

    loop {
        match listener.accept().await {
            Ok((stream, _addr)) => {
                let ctx = ctx.clone();

                tokio::spawn(async move {
                    if let Err(e) = handler::handle_client(stream, ctx).await {
                        eprintln!("IPC server error: {}", e);
                    }
                });
            }
            Err(e) => {
                eprintln!("IPC server error: {}", e);
                break;
            }
        }
    }
    Ok(())
}

#[cfg(unix)]
fn set_socket_permissions(path: &std::path::Path) -> std::io::Result<()> {
    use std::os::unix::fs::PermissionsExt;
    std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o600))
}
