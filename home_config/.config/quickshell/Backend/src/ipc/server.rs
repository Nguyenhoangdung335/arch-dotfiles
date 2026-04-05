use std::sync::Arc;

use tokio::net::UnixListener;
use tracing::{error, info};

use crate::app::AppContext;
use crate::config;
use crate::ipc::client::IPCClient;

pub async fn start(ctx: Arc<AppContext>) -> anyhow::Result<()> {
    let socket_path = ctx.config().await.server.socket_path.clone();
    let socket_path = config::socket_path(&socket_path);

    if let Some(parent) = socket_path.parent() {
        tokio::fs::create_dir_all(parent).await?;
    }
    if socket_path.exists() {
        tokio::fs::remove_file(&socket_path).await.map_err(|e| {
            error!("Failed to remove old socket: {}", e);
            e
        })?;
    }
    let listener = UnixListener::bind(&socket_path)?;
    set_socket_permissions(&socket_path)?;
    info!("IPC server listening on {:?}", socket_path);

    let mut join_set = tokio::task::JoinSet::new();

    loop {
        tokio::select! {
            result = listener.accept() => {
                match result {
                    Ok((stream, _addr)) => {
                        let ctx = ctx.clone();
                        let Ok(mut client) = IPCClient::new(ctx).await else{
                            error!("Failed to create IPC client");
                            continue;
                        };
                        join_set.spawn(async move {
                            if let Err(e) = client.handle_client(stream).await {
                                error!("IPC server error: {}", e);
                            }
                        });
                    }
                    Err(e) => {
                        error!("IPC server error: {}", e);
                        break;
                    }
                }
            },
            _ = ctx.cancel_token.cancelled() => {
                info!("Shutdown signal received, exiting IPC server loop...");
                break;
            }
        }
    }

    info!("Waiting for IPC clients to finish...");
    while join_set.join_next().await.is_some() {}

    if socket_path.exists() {
        tokio::fs::remove_file(&socket_path).await.map_err(|e| {
            error!("Failed to remove old socket: {}", e);
            e
        })?;
    }
    Ok(())
}

#[cfg(unix)]
fn set_socket_permissions(path: &std::path::Path) -> std::io::Result<()> {
    use std::os::unix::fs::PermissionsExt;
    std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o600))
}
