#[derive(Debug, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "snake_case")]
pub enum NetworkAction {
    ToggleWifi,
    ScanWifi,
    Connect { ssid: String },
    GetWifiDeviceObjectPath,
}
