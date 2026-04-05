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
    let mut path = dirs::config_dir().unwrap_or_else(|| {
        let user = env::var("USER").unwrap_or_else(|_| "1000".to_string());
        PathBuf::from(format!("/tmp/quickshell-{}/config", user))
    });
    path.push(config::SERVICE_NAME);
    path.push(config::CONFIG_FILE);
    path
}

pub fn socket_path(socket_path: &str) -> PathBuf {
    if socket_path.contains("$XDG_RUNTIME_DIR") {
        let runtime_dir = dirs::runtime_dir()
            .map(|p| p.to_string_lossy().into_owned())
            .or_else(|| env::var("XDG_RUNTIME_DIR").ok())
            .unwrap_or_else(|| {
                let user = env::var("USER").unwrap_or_else(|_| "1000".to_string());
                format!("/tmp/quickshell-{}", user)
            });
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

// region: config.rs unit tests

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    use std::sync::Mutex;

    static ENV_LOCK: Mutex<()> = Mutex::new(());

    struct EnvVarGuard {
        key: &'static str,
        previous: Option<String>,
    }

    impl EnvVarGuard {
        fn set(key: &'static str, value: &str) -> Self {
            let previous = env::var(key).ok();
            unsafe { env::set_var(key, value) };
            Self { key, previous }
        }

        fn remove(key: &'static str) -> Self {
            let previous = env::var(key).ok();
            unsafe { env::remove_var(key) };
            Self { key, previous }
        }
    }

    impl Drop for EnvVarGuard {
        fn drop(&mut self) {
            match self.previous {
                Some(ref value) => unsafe { env::set_var(self.key, value) },
                None => unsafe { env::remove_var(self.key) },
            }
        }
    }

    #[test]
    fn test_socket_path_without_xdg_runtime_dir() {
        let _lock = ENV_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        // Ensure XDG_RUNTIME_DIR is not set
        let _guard = EnvVarGuard::remove("XDG_RUNTIME_DIR");
        let result = socket_path("/tmp/test.sock");
        assert_eq!(result, std::path::PathBuf::from("/tmp/test.sock"));
    }

    #[test]
    fn test_socket_path_with_xdg_runtime_dir() {
        let _lock = ENV_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        let _guard = EnvVarGuard::set("XDG_RUNTIME_DIR", "/custom/runtime");
        let result = socket_path("$XDG_RUNTIME_DIR/shell.sock");
        assert_eq!(
            result,
            std::path::PathBuf::from("/custom/runtime/shell.sock")
        );
    }

    #[test]
    fn test_socket_path_multiple_occurrences() {
        let _lock = ENV_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        let _guard = EnvVarGuard::set("XDG_RUNTIME_DIR", "/tmp/runtime");
        let result = socket_path("$XDG_RUNTIME_DIR/app_$XDG_RUNTIME_DIR.sock");
        assert_eq!(
            result,
            std::path::PathBuf::from("/tmp/runtime/app_/tmp/runtime.sock")
        );
    }

    #[test]
    fn test_socket_path_no_replacement_needed() {
        let _lock = ENV_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        // No environment variable changes needed
        let result = socket_path("/var/run/test.sock");
        assert_eq!(result, std::path::PathBuf::from("/var/run/test.sock"));
    }
}

// endregion
