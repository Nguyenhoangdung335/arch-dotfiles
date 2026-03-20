#![allow(dead_code)]

#[derive(Debug, PartialEq)]
pub enum NMState {
    Unknown = 0,
    Asleep = 10,
    Disconnected = 20,
    Disconnecting = 30,
    Connecting = 40,
    ConnectedLocal = 50,
    ConnectedSite = 60,
    ConnectedGlobal = 70,
}

#[derive(Debug, PartialEq)]
pub enum NMConnectivity {
    Unknown = 0,
    None = 1,
    Portal = 2,
    Limited = 3,
    Full = 4,
}

#[derive(Debug, PartialEq)]
pub enum NMDeviceType {
    Unknown = 0,
    Ethernet = 1,
    WiFi = 2,
    Bluteooth = 5,
    Modrm = 8,
    VLan = 11,
    Bridge = 13,
}
