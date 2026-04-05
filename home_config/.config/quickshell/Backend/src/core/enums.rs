#[derive(Debug, serde::Deserialize, serde::Serialize, PartialEq, Clone)]
#[serde(rename_all = "lowercase")]
pub enum IPCModule {
    Network,
}
