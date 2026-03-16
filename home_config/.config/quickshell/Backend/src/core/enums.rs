#[derive(Debug, serde::Deserialize, serde::Serialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum IPCModule {
    Network,
}

#[derive(Debug, serde::Deserialize, serde::Serialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum NMDeviceType {
    Unknown = 0,
    Ethernet = 1,
    WiFi = 2,
    Bluteooth = 5,
    Modrm = 8,
    VLan = 11,
    Bridge = 13,
}
