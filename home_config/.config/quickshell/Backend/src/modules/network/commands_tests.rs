use super::*;
use crate::modules::network::state::{SavedConnection, WifiAccessPoint};

#[test]
fn test_connection_routing_existing() {
    let mut state = NetworkState {
        wifi_device_object_path: Some("/org/freedesktop/NetworkManager/Devices/3".to_string()),
        ..NetworkState::default()
    };

    let conn = SavedConnection {
        ssid: "MyNetwork".to_string(),
        object_path: "/org/freedesktop/NetworkManager/Settings/1".to_string(),
        connection_type: "802-11-wireless".to_string(),
        timestamp: 1000,
    };
    state.saved_connections.push(conn);

    let ap = WifiAccessPoint {
        ssid: "MyNetwork".to_string(),
        object_path: "/org/freedesktop/NetworkManager/AccessPoint/2".to_string(),
        strength: 80,
        frequency: 2400,
        hw_address: "00:11:22:33:44:55".to_string(),
        secure: true,
        flags: 0,
        wpa_flags: 0,
        rsn_flags: 0,
        mode: 0,
        connected: false,
        band: "".to_string(),
        channel: 0,
    };
    state.wifi_access_points.push(ap);

    let (saved_conn_path, wifi_device_path, ap_path, secure) =
        NetworkCommand::resolve_connection_params(&state, "MyNetwork").unwrap();

    assert_eq!(
        saved_conn_path.unwrap(),
        "/org/freedesktop/NetworkManager/Settings/1"
    );
    assert_eq!(
        wifi_device_path,
        "/org/freedesktop/NetworkManager/Devices/3"
    );
    assert_eq!(ap_path, "/org/freedesktop/NetworkManager/AccessPoint/2");
    assert!(secure);
}

#[test]
fn test_connection_routing_duplicate_ssids() {
    let mut state = NetworkState {
        wifi_device_object_path: Some("/org/freedesktop/NetworkManager/Devices/3".to_string()),
        ..NetworkState::default()
    };

    let conn1 = SavedConnection {
        ssid: "MyNetwork".to_string(),
        object_path: "/org/freedesktop/NetworkManager/Settings/1".to_string(),
        connection_type: "802-11-wireless".to_string(),
        timestamp: 1000,
    };
    let conn2 = SavedConnection {
        ssid: "MyNetwork".to_string(),
        object_path: "/org/freedesktop/NetworkManager/Settings/2".to_string(),
        connection_type: "802-11-wireless".to_string(),
        timestamp: 2000,
    };
    // conn2 has a higher timestamp, so it should be selected
    state.saved_connections.push(conn1);
    state.saved_connections.push(conn2);

    let (saved_conn_path, _, _, _) =
        NetworkCommand::resolve_connection_params(&state, "MyNetwork").unwrap();

    assert_eq!(
        saved_conn_path.unwrap(),
        "/org/freedesktop/NetworkManager/Settings/2"
    );
}
