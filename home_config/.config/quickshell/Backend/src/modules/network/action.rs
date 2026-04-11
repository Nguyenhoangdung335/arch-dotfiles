#[derive(Debug, serde::Deserialize, serde::Serialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum NetworkAction {
    Connect {
        ssid: String,
        password: Option<String>,
    },
    GetWifiDeviceObjectPath,
    GetHostname,
    GetSavedConnections,
    ScanWifi,
    GetCurrentState,
    ToggleWifi,
}
