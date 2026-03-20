use std::sync::Arc;

use notify::RecommendedWatcher;
use notify_debouncer_mini::Debouncer;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

use crate::config::watch_config;
use crate::core::config;
use crate::modules::network::NetworkModule;

pub struct AppContext {
    pub cfg: Arc<RwLock<config::Config>>,
    pub cancel_token: CancellationToken,
    pub _cfg_watcher: Debouncer<RecommendedWatcher>,
    pub network: NetworkModule,
}

impl AppContext {
    pub async fn new(
        sys_bus: &zbus::Connection,
        cfg: Arc<RwLock<config::Config>>,
        cancel_token: CancellationToken,
    ) -> anyhow::Result<Arc<Self>> {
        let network = NetworkModule::new(&sys_bus.clone(), cancel_token.child_token()).await?;
        let _cfg_watcher = watch_config(cfg.clone()).await?;

        Ok(Arc::new(Self {
            network,
            cfg,
            cancel_token,
            _cfg_watcher,
        }))
    }

    pub async fn config(&self) -> tokio::sync::RwLockReadGuard<'_, config::Config> {
        self.cfg.read().await
    }
}
