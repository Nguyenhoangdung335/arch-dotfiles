use std::fs;

use tempfile::TempDir;
use serial_test::serial;

use Backend::config::{config_path, load_or_create_config};
use Backend::core::config::{Config, NetworkConfig, ModuleConfig, ServerConfig};

static ENV_LOCK: std::sync::Mutex<()> = std::sync::Mutex::new(());

#[serial]
#[tokio::test]
async fn test_config_path_creates_directory() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    let config_dir = temp_dir.path().join("config");
    std::fs::create_dir_all(&config_dir).expect("Failed to create config dir");
    // Ensure the config directory exists (custom_qs subdirectory)
    let custom_qs_dir = config_dir.join("custom_qs");
    std::fs::create_dir_all(&custom_qs_dir).expect("Failed to create custom_qs dir");
    
    // Temporarily override config directory
    let _home_guard = set_env_var("HOME", temp_dir.path().to_str().unwrap());
    let _xdg_guard = set_env_var("XDG_CONFIG_HOME", config_dir.to_str().unwrap());
    
    let path = config_path();
    assert!(path.to_string_lossy().contains("config"));
    assert!(path.parent().unwrap().exists());
}

#[serial]
#[tokio::test]
async fn test_load_or_create_config_creates_default() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    let config_dir_path = temp_dir.path().join("config");
    fs::create_dir_all(&config_dir_path).expect("Failed to create config dir");
    
    // Temporarily override config directory
    let _home_guard = set_env_var("HOME", temp_dir.path().to_str().unwrap());
    let _xdg_guard = set_env_var("XDG_CONFIG_HOME", config_dir_path.to_str().unwrap());
    

    
    // This should create a default config file
    let config = load_or_create_config().await.expect("Failed to load/create config");
    assert_eq!(config, Config::default());
    
    // Verify the file was created
    let config_path = config_path();
    assert!(config_path.exists());

}

#[serial]
#[tokio::test]
async fn test_load_or_create_config_loads_existing() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    let config_dir_path = temp_dir.path().join("config");
    fs::create_dir_all(&config_dir_path).expect("Failed to create config dir");
    
    // Temporarily override config directory
    let _home_guard = set_env_var("HOME", temp_dir.path().to_str().unwrap());
    let _xdg_guard = set_env_var("XDG_CONFIG_HOME", config_dir_path.to_str().unwrap());
    
    // config_path includes a 'custom_qs' subdirectory; ensure it exists before writing.
    let custom_qs_dir = config_dir_path.join("custom_qs");
    std::fs::create_dir_all(&custom_qs_dir).expect("Failed to create custom_qs dir");
    
    // Create a custom config first
    let custom_config = Config {
        server: ServerConfig {
            socket_path: "/custom/path.sock".to_string(),
        },
        module: ModuleConfig {
            network: NetworkConfig { enabled: false },
        },
    };
    
    let config_path = config_path();
    let config_str = toml::to_string_pretty(&custom_config).expect("Failed to serialize config");
    fs::write(&config_path, config_str).expect("Failed to write config file");
    
    // Now load it - should return our custom config
    let loaded_config = load_or_create_config().await.expect("Failed to load config");
    assert_eq!(loaded_config.server.socket_path, "/custom/path.sock");
    assert!(!loaded_config.module.network.enabled);
}

// Helper to set environment variables (thread-safe via lock)
fn set_env_var<'a>(key: &'a str, value: &str) -> impl Drop + 'a {
    let _lock = ENV_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let previous = std::env::var(key).ok();
    unsafe { std::env::set_var(key, value) };
    struct EnvGuard<'a> {
        key: &'a str,
        previous: Option<String>,
    }
    impl<'a> Drop for EnvGuard<'a> {
        fn drop(&mut self) {
            let _lock = ENV_LOCK.lock().unwrap_or_else(|e| e.into_inner());
            match &self.previous {
                Some(v) => unsafe { std::env::set_var(self.key, v) },
                None => unsafe { std::env::remove_var(self.key) },
            }
        }
    }
    EnvGuard { key, previous }
}