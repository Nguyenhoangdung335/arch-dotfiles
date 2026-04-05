pub const CONFIG_FILE: &str = "config.toml";
pub const SERVICE_NAME: &str = "shell-ricing";

#[derive(Debug, serde::Deserialize, serde::Serialize, Clone, PartialEq)]
pub struct Config {
    pub server: ServerConfig,
    pub module: ModuleConfig,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            server: ServerConfig {
                socket_path: "$XDG_RUNTIME_DIR/shell-ricing/shell.sock".to_string(),
            },
            module: ModuleConfig {
                network: NetworkConfig { enabled: true },
            },
        }
    }
}

// region: Nested Config structs

#[derive(Debug, serde::Deserialize, serde::Serialize, Clone, PartialEq)]
pub struct ServerConfig {
    pub socket_path: String,
}

#[derive(Debug, serde::Deserialize, serde::Serialize, Clone, PartialEq)]
pub struct ModuleConfig {
    pub network: NetworkConfig,
}

#[derive(Debug, serde::Deserialize, serde::Serialize, Clone, PartialEq)]
pub struct NetworkConfig {
    pub enabled: bool,
}

// endregion
