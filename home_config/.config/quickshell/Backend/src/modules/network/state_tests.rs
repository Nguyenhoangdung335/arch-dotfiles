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

#[test]
fn test_wifi_access_point_ssid_utf8_lossy() {
    let mut map = HashMap::new();
    // Invalid utf8 bytes
    map.insert(
        "Ssid".to_string(),
        zbus::zvariant::OwnedValue::try_from(zbus::zvariant::Value::from(vec![255u8, 254u8]))
            .unwrap(),
    );
    map.insert(
        "HwAddress".to_string(),
        zbus::zvariant::OwnedValue::try_from(zbus::zvariant::Value::from("00:00:00:00:00:00"))
            .unwrap(),
    );
    let ap = WifiAccessPoint::try_from(map).unwrap();
    assert_eq!(ap.ssid, "\u{FFFD}\u{FFFD}"); // replacement character
}
