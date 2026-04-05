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

#[cfg(test)]
mod tests {
    use super::*;

    // NMState tests
    #[test]
    fn test_nmstate_from_unknown() {
        assert_eq!(NMState::from(0), NMState::Unknown);
    }

    #[test]
    fn test_nmstate_from_asleep() {
        assert_eq!(NMState::from(10), NMState::Asleep);
    }

    #[test]
    fn test_nmstate_from_disconnected() {
        assert_eq!(NMState::from(20), NMState::Disconnected);
    }

    #[test]
    fn test_nmstate_from_disconnecting() {
        assert_eq!(NMState::from(30), NMState::Disconnecting);
    }

    #[test]
    fn test_nmstate_from_connecting() {
        assert_eq!(NMState::from(40), NMState::Connecting);
    }

    #[test]
    fn test_nmstate_from_connected_local() {
        assert_eq!(NMState::from(50), NMState::ConnectedLocal);
    }

    #[test]
    fn test_nmstate_from_connected_site() {
        assert_eq!(NMState::from(60), NMState::ConnectedSite);
    }

    #[test]
    fn test_nmstate_from_connected_global() {
        assert_eq!(NMState::from(70), NMState::ConnectedGlobal);
    }

    #[test]
    fn test_nmstate_from_invalid_returns_unknown() {
        assert_eq!(NMState::from(999), NMState::Unknown);
    }

    // NMConnectivity tests
    #[test]
    fn test_nmconnectivity_from_unknown() {
        assert_eq!(NMConnectivity::from(0), NMConnectivity::Unknown);
    }

    #[test]
    fn test_nmconnectivity_from_none() {
        assert_eq!(NMConnectivity::from(1), NMConnectivity::None);
    }

    #[test]
    fn test_nmconnectivity_from_portal() {
        assert_eq!(NMConnectivity::from(2), NMConnectivity::Portal);
    }

    #[test]
    fn test_nmconnectivity_from_limited() {
        assert_eq!(NMConnectivity::from(3), NMConnectivity::Limited);
    }

    #[test]
    fn test_nmconnectivity_from_full() {
        assert_eq!(NMConnectivity::from(4), NMConnectivity::Full);
    }

    #[test]
    fn test_nmconnectivity_from_invalid_returns_unknown() {
        assert_eq!(NMConnectivity::from(999), NMConnectivity::Unknown);
    }

    // NMDeviceType tests
    #[test]
    fn test_nmdevicetype_from_unknown() {
        assert_eq!(NMDeviceType::from(0), NMDeviceType::Unknown);
    }

    #[test]
    fn test_nmdevicetype_from_ethernet() {
        assert_eq!(NMDeviceType::from(1), NMDeviceType::Ethernet);
    }

    #[test]
    fn test_nmdevicetype_from_wifi() {
        assert_eq!(NMDeviceType::from(2), NMDeviceType::WiFi);
    }

    #[test]
    fn test_nmdevicetype_from_bluetooth() {
        assert_eq!(NMDeviceType::from(5), NMDeviceType::Bluetooth);
    }

    #[test]
    fn test_nmdevicetype_from_modem() {
        assert_eq!(NMDeviceType::from(8), NMDeviceType::Modrm);
    }

    #[test]
    fn test_nmdevicetype_from_vlan() {
        assert_eq!(NMDeviceType::from(11), NMDeviceType::VLan);
    }

    #[test]
    fn test_nmdevicetype_from_bridge() {
        assert_eq!(NMDeviceType::from(13), NMDeviceType::Bridge);
    }

    #[test]
    fn test_nmdevicetype_from_invalid_returns_unknown() {
        assert_eq!(NMDeviceType::from(999), NMDeviceType::Unknown);
    }
}
