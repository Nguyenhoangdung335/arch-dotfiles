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

impl From<u32> for NMState {
    fn from(value: u32) -> Self {
        match value {
            0 => Self::Unknown,
            10 => Self::Asleep,
            20 => Self::Disconnected,
            30 => Self::Disconnecting,
            40 => Self::Connecting,
            50 => Self::ConnectedLocal,
            60 => Self::ConnectedSite,
            70 => Self::ConnectedGlobal,
            _ => Self::Unknown,
        }
    }
}

#[derive(Debug, PartialEq)]
pub enum NMConnectivity {
    Unknown = 0,
    None = 1,
    Portal = 2,
    Limited = 3,
    Full = 4,
}

impl From<u32> for NMConnectivity {
    fn from(value: u32) -> Self {
        match value {
            0 => Self::Unknown,
            1 => Self::None,
            2 => Self::Portal,
            3 => Self::Limited,
            4 => Self::Full,
            _ => Self::Unknown,
        }
    }
}

#[derive(Debug, PartialEq)]
pub enum NMDeviceType {
    Unknown = 0,
    Ethernet = 1,
    WiFi = 2,
    Bluetooth = 5,
    Modrm = 8,
    VLan = 11,
    Bridge = 13,
}

impl From<u32> for NMDeviceType {
    fn from(value: u32) -> Self {
        match value {
            0 => Self::Unknown,
            1 => Self::Ethernet,
            2 => Self::WiFi,
            5 => Self::Bluetooth,
            8 => Self::Modrm,
            11 => Self::VLan,
            13 => Self::Bridge,
            _ => Self::Unknown,
        }
    }
}


    }
}
