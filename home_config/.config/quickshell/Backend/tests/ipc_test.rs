use serde_json::json;
use Backend::ipc::client::{ClientRequest, ResponseEvent};
use Backend::core::enums::IPCModule;
use Backend::modules::network::action::NetworkAction;

#[tokio::test]
async fn test_client_request_serialization() {
    // Test Network action serialization
    let request = ClientRequest::Network(NetworkAction::ScanWifi);
    let serialized = serde_json::to_string(&request).expect("Failed to serialize");
    let expected = json!({"module":"network","action":"scan_wifi"});
    let serialized_value: serde_json::Value = serde_json::from_str(&serialized).expect("Failed to parse serialized");
    assert_eq!(serialized_value, expected);
    
    // Test Connect action serialization
    let request = ClientRequest::Network(NetworkAction::Connect { ssid: "test-network".to_string() });
    let serialized = serde_json::to_string(&request).expect("Failed to serialize");
    let expected = json!({"module":"network","action":{"connect":{"ssid":"test-network"}}});
    let serialized_value: serde_json::Value = serde_json::from_str(&serialized).expect("Failed to parse serialized");
    assert_eq!(serialized_value, expected);
}

#[tokio::test]
async fn test_client_request_deserialization() {
    // Test Network action deserialization
    let json = json!({"module":"network","action":"scan_wifi"}).to_string();
    let request: ClientRequest = serde_json::from_str(&json).expect("Failed to deserialize");
    assert!(matches!(request, ClientRequest::Network(NetworkAction::ScanWifi)));
    
    // Test Connect action deserialization
    let json = json!({"module":"network","action":{"connect":{"ssid":"my-wifi"}}}).to_string();
    let request: ClientRequest = serde_json::from_str(&json).expect("Failed to deserialize");
    if let ClientRequest::Network(NetworkAction::Connect { ssid }) = request {
        assert_eq!(ssid, "my-wifi");
    } else {
        panic!("Expected Connect action");
    }
}

#[tokio::test]
async fn test_response_event_serialization() {
    // Test successful serialization
    let response = ResponseEvent {
        module: IPCModule::Network,
        data: json!({"ssid": "test", "strength": 75}),
    };
    let serialized = serde_json::to_string(&response).expect("Failed to serialize");
    assert!(serialized.contains("\"module\":\"network\""));
    assert!(serialized.contains("\"ssid\":\"test\""));
    assert!(serialized.contains("\"strength\":75"));
}

#[tokio::test]
async fn test_response_event_deserialization() {
    // Test deserialization
    let json = r#"{"module":"network","data":{"ssid":"test","strength":80}}"#;
    let response: ResponseEvent<serde_json::Value> = serde_json::from_str(json).expect("Failed to deserialize");
    assert_eq!(response.module, IPCModule::Network);
    assert_eq!(response.data["ssid"], "test");
    assert_eq!(response.data["strength"], 80);
}