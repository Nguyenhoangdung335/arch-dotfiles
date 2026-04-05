mod app;
mod config;
mod core;
mod ipc;
mod modules;
mod utils;

use std::sync::Arc;

use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::fmt::layer(), // .with_span_events(tracing_subscriber::fmt::format::FmtSpan::CLOSE),
        ) // Output to console
        .with(tracing_subscriber::EnvFilter::from_default_env()) // Enable RUST_LOG
        .init();

    let cfg = Arc::new(RwLock::new(config::load_or_create_config().await?));
    let sys_bus = zbus::Connection::system().await?;
    // Uncomment when used for other services
    // let ses_bus = zbus::Connection::session().await?;
    let cancel_token = CancellationToken::new();

    let cloned_cancel_token = cancel_token.clone();
    tokio::spawn(async move {
        let mut sigterm = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("failed to install SIGTERM handler");
        tokio::select! {
            _ = tokio::signal::ctrl_c() => {
                tracing::info!("Ctrl+C pressed, shutting down...");
                cloned_cancel_token.cancel();
            },
            _ = sigterm.recv() => {
                tracing::info!("SIGTERM received, shutting down...");
                cloned_cancel_token.cancel();
            }
        };
    });

    let app_ctx = app::AppContext::new(&sys_bus, cfg, cancel_token).await?;
    ipc::server::start(app_ctx.clone()).await?;

    app_ctx.shutdown().await;

    Ok(())
}
