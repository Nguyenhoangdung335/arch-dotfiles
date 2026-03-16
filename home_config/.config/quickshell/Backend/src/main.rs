mod app;
mod config;
mod core;
mod ipc;
mod modules;
mod utils;

use std::error::Error;
use std::sync::Arc;

use tokio::sync::RwLock;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn Error>> {
    let cfg = Arc::new(RwLock::new(config::load_or_create_config().await?));
    let sys_bus = zbus::Connection::system().await?;
    // Uncomment when used for other services
    // let ses_bus = zbus::Connection::session().await?;

    let app_ctx = app::AppContext::new(&sys_bus, cfg).await?;
    ipc::server::start(app_ctx).await?;

    Ok(())
}
