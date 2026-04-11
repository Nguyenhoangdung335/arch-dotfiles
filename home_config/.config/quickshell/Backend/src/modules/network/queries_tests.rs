use super::*;
use std::collections::HashMap;
use zbus::zvariant::{OwnedValue, Value};

#[test]
fn test_parse_missing_connection_dict() {
    let settings = HashMap::new();
    // Omit "connection" key entirely.

    let result = NetworkQuery::parse_saved_connection_dict(
        "/org/freedesktop/NetworkManager/Settings/1",
        settings,
    );
    assert!(
        result.is_none(),
        "Should return None when 'connection' key is missing"
    );
}

#[test]
fn test_parse_invalid_utf8_ssid() {
    let mut settings = HashMap::new();

    let mut conn_map = HashMap::new();
    conn_map.insert(
        "type".to_string(),
        OwnedValue::try_from(Value::from("802-11-wireless")).unwrap(),
    );
    settings.insert("connection".to_string(), conn_map);

    let mut wifi_map = HashMap::new();
    // Invalid UTF-8 sequence
    let invalid_utf8_bytes: Vec<u8> = vec![0xff, 0xfe, 0xfd];
    wifi_map.insert(
        "ssid".to_string(),
        OwnedValue::try_from(Value::from(invalid_utf8_bytes)).unwrap(),
    );
    settings.insert("802-11-wireless".to_string(), wifi_map);

    let result = NetworkQuery::parse_saved_connection_dict("/path", settings);
    assert!(result.is_some());
    let saved_conn = result.unwrap();
    assert_eq!(
        saved_conn.ssid,
        String::from_utf8_lossy(&[0xff, 0xfe, 0xfd]).into_owned()
    );
}

#[test]
fn test_filter_exact_wireless_type() {
    let mut settings = HashMap::new();

    let mut conn_map = HashMap::new();
    // Wrong casing
    conn_map.insert(
        "type".to_string(),
        OwnedValue::try_from(Value::from("802-11-WIRELESS")).unwrap(),
    );
    settings.insert("connection".to_string(), conn_map);

    let result = NetworkQuery::parse_saved_connection_dict("/path", settings);
    assert!(
        result.is_none(),
        "Should reject non-exact match '802-11-WIRELESS'"
    );
}
