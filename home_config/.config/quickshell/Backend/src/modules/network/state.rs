use std::collections::HashMap;

use phf::phf_map;
use tokio::sync::watch::{self, Receiver, Sender};
use tracing::debug;
use zbus::zvariant::{ObjectPath, OwnedValue};

// region: constant

pub static WIFI_CHANNEL_MAP: phf::Map<u32, u32> = phf_map! {
    // 2.4 GHz
    2412u32 => 1, 2417 => 2, 2422 => 3, 2427 => 4,
    2432 => 5, 2437 => 6, 2442 => 7, 2447 => 8,
    2452 => 9, 2457 => 10, 2462 => 11, 2467 => 12,
    2472 => 13, 2484 => 14,

    // 5 GHz
    5180 => 36, 5200 => 40, 5220 => 44, 5240 => 48,
    5260 => 52, 5280 => 56, 5300 => 60, 5320 => 64,
    5500 => 100, 5520 => 104, 5540 => 108, 5560 => 112,
    5580 => 116, 5600 => 120, 5620 => 124, 5640 => 128,
    5660 => 132, 5680 => 136, 5700 => 140, 5720 => 144,
    5745 => 149, 5765 => 153, 5785 => 157, 5805 => 161,
    5825 => 165,
};

// endregion

#[derive(Clone, Debug, serde::Serialize, PartialEq, Eq)]
pub struct WifiAccessPoint {
    pub hw_address: String,  // s
    pub ssid: String,        // ay
    pub strength: u8,        // y
    pub frequency: u32,      // u
    pub flags: u32,          // u
    pub wpa_flags: u32,      // u
    pub rsn_flags: u32,      // u
    pub mode: u32,           // u
    pub object_path: String, // zvariant::OwnedObjectPath
    pub connected: bool,     // derive from ActiveConnection
    pub band: String,        // derive from frequency
    pub channel: u32,        // derive from frequency
    pub secure: bool,        // derive from flags, wpa_flags, and rsn_flags
}

// region: WifiAccessPoint impl

impl TryFrom<HashMap<String, OwnedValue>> for WifiAccessPoint {
    type Error = anyhow::Error;

    fn try_from(mut map: HashMap<String, OwnedValue>) -> Result<Self, Self::Error> {
        Ok(Self {
            ssid: String::from_utf8_lossy(&take::<Vec<u8>>(&mut map, "Ssid")?).into_owned(),
            hw_address: take(&mut map, "HwAddress")?,
            strength: take_or(&mut map, "Strength", 0),
            frequency: take_or(&mut map, "Frequency", 0),
            flags: take_or(&mut map, "Flags", 0),
            wpa_flags: take_or(&mut map, "WpaFlags", 0),
            rsn_flags: take_or(&mut map, "RsnFlags", 0),
            mode: take_or(&mut map, "Mode", 0),
            object_path: ObjectPath::default().to_string(),
            connected: false,
            band: String::from("unknown"),
            channel: 0,
            secure: false,
        })
    }
}

impl WifiAccessPoint {
    pub fn try_from_properties_with_path(
        properties: HashMap<String, OwnedValue>,
        path: &ObjectPath,
    ) -> anyhow::Result<Self> {
        let mut this = Self::try_from(properties)?;
        this.object_path = path.to_string();
        this.band = String::from(this.band_from_frequency());
        this.channel = this.channel_from_frequency();
        this.secure = this.is_secured();
        Ok(this)
    }

    pub fn band_from_frequency(&self) -> &str {
        match self.frequency {
            2400..=2484 => "2.4GHz",
            5150..=5850 => "5GHz",
            5925..=7125 => "6GHz",
            _ => "unknown",
        }
    }

    pub fn channel_from_frequency(&self) -> u32 {
        if let Some(channel) = WIFI_CHANNEL_MAP.get(&self.frequency) {
            return *channel;
        }
        // 6 GHz fallback
        if (5955..=7115).contains(&self.frequency) && (self.frequency - 5955).is_multiple_of(5) {
            return (self.frequency - 5955) / 5 + 1;
        }
        // Final fallback
        0
    }

    pub fn is_secured(&self) -> bool {
        // 0x1 is NM_802_11_AP_FLAGS_PRIVACY
        // If this flag is set, or if there are any WPA/RSN flags, the network is secured.
        (self.flags & 0x1) != 0 || self.wpa_flags != 0 || self.rsn_flags != 0
    }
}

// endregion

#[derive(Clone, Debug, serde::Serialize, Default, PartialEq, Eq)]
pub struct NetworkState {
    pub wifi_access_points: Vec<WifiAccessPoint>,
    pub wireless_enabled: bool,                       // b
    pub networking_enabled: bool,                     // b
    pub state: u8,                                    // u
    pub connectivity: u8,                             // u
    pub active_access_point: Option<WifiAccessPoint>, // o
    pub hostname: String,                             // s
    pub wifi_device_object_path: Option<String>,      // internal use
}

impl NetworkState {
    pub fn create_state_watcher() -> (Sender<NetworkState>, Receiver<NetworkState>) {
        watch::channel(NetworkState::default())
    }
}

// region: Helpers

fn take<T>(map: &mut HashMap<String, OwnedValue>, key: &str) -> anyhow::Result<T>
where
    T: TryFrom<OwnedValue>,
    T::Error: std::error::Error + Send + Sync + 'static,
{
    let value = map
        .remove(key)
        .ok_or_else(|| anyhow::anyhow!("Missing key: {}", key))?;

    T::try_from(value).map_err(|e| anyhow::anyhow!("Invalid {}: {}", key, e))
}

fn take_or<T>(map: &mut HashMap<String, OwnedValue>, key: &str, default: T) -> T
where
    T: TryFrom<OwnedValue>,
{
    map.remove(key)
        .and_then(|v| T::try_from(v).ok())
        .unwrap_or_else(|| {
            debug!("Missing key: {}", key);
            default
        })
}

// endregion

#[cfg(test)]
mod tests {
    use super::*;

    // band_from_frequency tests
    #[test]
    fn test_band_from_frequency_24ghz() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 2437,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.band_from_frequency(), "2.4GHz");
    }

    #[test]
    fn test_band_from_frequency_5ghz() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 5180,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.band_from_frequency(), "5GHz");
    }

    #[test]
    fn test_band_from_frequency_6ghz() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 5925,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.band_from_frequency(), "6GHz");
    }

    #[test]
    fn test_band_from_frequency_unknown() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 9999,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.band_from_frequency(), "unknown");
    }

    // channel_from_frequency tests
    #[test]
    fn test_channel_from_frequency_24ghz() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 2412,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.channel_from_frequency(), 1);
    }

    #[test]
    fn test_channel_from_frequency_5ghz() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 5180,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.channel_from_frequency(), 36);
    }

    #[test]
    fn test_channel_from_frequency_6ghz() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 5955,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.channel_from_frequency(), 1);
    }

    #[test]
    fn test_channel_from_frequency_unknown_returns_zero() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 9999,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert_eq!(ap.channel_from_frequency(), 0);
    }

    // is_secured tests
    #[test]
    fn test_is_secured_with_privacy_flag() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 0,
            flags: 0x1, // NM_802_11_AP_FLAGS_PRIVACY
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert!(ap.is_secured());
    }

    #[test]
    fn test_is_secured_with_wpa_flags() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 0,
            flags: 0,
            wpa_flags: 0x1,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert!(ap.is_secured());
    }

    #[test]
    fn test_is_secured_with_rsn_flags() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 0,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0x1,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert!(ap.is_secured());
    }

    #[test]
    fn test_is_secured_not_secured() {
        let ap = WifiAccessPoint {
            hw_address: String::new(),
            ssid: String::new(),
            strength: 0,
            frequency: 0,
            flags: 0,
            wpa_flags: 0,
            rsn_flags: 0,
            mode: 0,
            object_path: String::new(),
            connected: false,
            band: String::new(),
            channel: 0,
            secure: false,
        };
        assert!(!ap.is_secured());
    }

    // NetworkState tests
    #[test]
    fn test_network_state_default() {
        let state = NetworkState::default();
        assert!(state.wifi_access_points.is_empty());
        assert!(!state.wireless_enabled);
        assert!(!state.networking_enabled);
        assert!(state.active_access_point.is_none());
        assert!(state.hostname.is_empty());
        assert!(state.wifi_device_object_path.is_none());
    }

    #[test]
    fn test_network_state_create_state_watcher() {
        let (tx, rx) = NetworkState::create_state_watcher();
        assert!(tx.send(NetworkState::default()).is_ok());
        let state = rx.borrow();
        assert!(state.wifi_access_points.is_empty());
    }
}
