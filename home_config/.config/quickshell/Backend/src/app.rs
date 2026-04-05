use std::sync::Arc;

use notify::RecommendedWatcher;
use notify_debouncer_mini::Debouncer;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

use crate::config::watch_config;
use crate::core::config;
use crate::modules::network::{NetworkActor, NetworkModuleHandle};

pub struct AppContext {
    pub cfg: Arc<RwLock<config::Config>>,
    pub cancel_token: CancellationToken,
    pub _cfg_watcher: Debouncer<RecommendedWatcher>,
    pub network_handle: NetworkModuleHandle,
}

impl AppContext {
    pub async fn new(
        sys_bus: &zbus::Connection,
        cfg: Arc<RwLock<config::Config>>,
        cancel_token: CancellationToken,
    ) -> anyhow::Result<Arc<Self>> {
        let network_handle = NetworkActor::spawn(sys_bus, cancel_token.child_token()).await?;
        let _cfg_watcher = watch_config(cfg.clone()).await?;

        Ok(Arc::new(Self {
            network_handle,
            cfg,
            cancel_token,
            _cfg_watcher,
        }))
    }

    pub async fn config(&self) -> tokio::sync::RwLockReadGuard<'_, config::Config> {
        self.cfg.read().await
    }

    pub async fn shutdown(&self) {
        if let Some(handle) = self.network_handle.join_handle.lock().await.take() {
            tracing::info!("Waiting for network actor to finish...");
            let _ = handle.await;
        }
    }
}
