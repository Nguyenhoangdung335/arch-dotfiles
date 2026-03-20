mod app;
mod config;
mod core;
mod ipc;
mod modules;
mod utils;

use std::error::Error;
use std::sync::Arc;

use tokio::sync::RwLock;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn Error>> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer()) // Output to console
        .with(tracing_subscriber::EnvFilter::from_default_env()) // Enable RUST_LOG
        .init();

    let cfg = Arc::new(RwLock::new(config::load_or_create_config().await?));
    let sys_bus = zbus::Connection::system().await?;
    // Uncomment when used for other services
    // let ses_bus = zbus::Connection::session().await?;

    let app_ctx = app::AppContext::new(&sys_bus, cfg).await?;
    ipc::server::start(app_ctx).await?;

    Ok(())
}
