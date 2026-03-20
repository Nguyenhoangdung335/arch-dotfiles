use std::env;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{Duration, SystemTime};

use notify::{RecommendedWatcher, RecursiveMode};
use notify_debouncer_mini::Debouncer;
use tokio::fs::{self, read_to_string};
use tokio::sync::RwLock;
use tokio::sync::mpsc::channel;
use tracing::{error, info};

use crate::core::config;

pub fn config_path() -> PathBuf {
    let mut path = dirs::config_dir().expect("config dir not found");
    path.push(config::SERVICE_NAME);
    path.push(config::CONFIG_FILE);
    path
}

pub fn socket_path(socket_path: &str) -> PathBuf {
    if socket_path.contains("$XDG_RUNTIME_DIR") {
        let runtime_dir = env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".to_string());
        PathBuf::from(socket_path.replace("$XDG_RUNTIME_DIR", &runtime_dir))
    } else {
        PathBuf::from(socket_path)
    }
}

pub async fn load_or_create_config() -> anyhow::Result<config::Config> {
    let path = config_path();
    match path.exists() {
        true => {
            let cfg_content = read_to_string(&path).await?;
            let cfg: config::Config = toml::from_str(&cfg_content)?;
            Ok(cfg)
        }
        false => {
            if let Some(parent) = path.parent() {
                fs::create_dir_all(parent).await?;
            }
            let default_cfg = config::Config::default();
            let toml = toml::to_string_pretty(&default_cfg)?;
            tokio::fs::write(&path, toml).await?;
            error!(
                "config file not found, created default config file at {:?}",
                path
            );
            Ok(default_cfg)
        }
    }
}

pub async fn watch_config(
    config: Arc<RwLock<config::Config>>,
) -> notify::Result<Debouncer<RecommendedWatcher>> {
    let (tx, mut rx) = channel(32);
    let mut debouncer =
        notify_debouncer_mini::new_debouncer(Duration::from_millis(200), move |result| {
            let _ = tx.blocking_send(result);
        })?;
    let path = config_path();
    let parent = path.parent().expect("config file not found");
    debouncer
        .watcher()
        .watch(parent, RecursiveMode::NonRecursive)?;

    tokio::spawn(async move {
        let mut last_mtime = SystemTime::UNIX_EPOCH;

        while let Some(res) = rx.recv().await {
            match res {
                Ok(events) => {
                    if events.iter().any(|e| {
                        e.path.file_name() == Some(std::ffi::OsStr::new(config::CONFIG_FILE))
                    }) {
                        // tokio::time::sleep(std::time::Duration::from_millis(50)).await;

                        if let Ok(meta) = tokio::fs::metadata(&path).await
                            && let Ok(current_mtime) = meta.modified()
                        {
                            if current_mtime <= last_mtime {
                                continue;
                            }
                            last_mtime = current_mtime;
                        }

                        // 3. Now it is safe to read the file
                        match load_or_create_config().await {
                            Ok(cfg) => {
                                let mut current_cfg = config.write().await;
                                if *current_cfg != cfg {
                                    *current_cfg = cfg;
                                    info!("config reloaded");
                                }
                            }
                            Err(e) => error!("config error: {:?}", e),
                        }
                    }
                }
                Err(e) => error!("watch error: {:?}", e),
            }
        }
    });

    Ok(debouncer)
}
