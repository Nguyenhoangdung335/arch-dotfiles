use tokio::sync::watch::{self, Receiver, Sender};

use crate::utils::compare::update_if_changed;

#[derive(Clone, Debug, serde::Serialize, PartialEq, Eq)]
pub struct WifiAccessPoint {
    pub ssid: String,        // ay
    pub strength: u8,        // y
    pub hw_address: String,  // s
    pub object_path: String, // zvariant::OwnedObjectPath
}

#[derive(Clone, Debug, serde::Serialize, Default, PartialEq, Eq)]
pub struct NetworkState {
    pub wifi_access_points: Vec<WifiAccessPoint>,
    pub wireless_enabled: bool,
    pub active_connection: Option<WifiAccessPoint>,
    pub wifi_device_object_path: Option<String>,
}

impl NetworkState {
    pub fn send_wireless_enabled_changed(&mut self, new_value: bool) -> bool {
        update_if_changed(&mut self.wireless_enabled, new_value)
    }

    pub fn send_wifi_device_object_path_changed(&mut self, new_value: Option<String>) -> bool {
        update_if_changed(&mut self.wifi_device_object_path, new_value)
    }

    pub fn send_wifi_access_points_changed(&mut self, new_value: Vec<WifiAccessPoint>) -> bool {
        update_if_changed(&mut self.wifi_access_points, new_value)
    }
}

pub fn create_network_state() -> (Sender<NetworkState>, Receiver<NetworkState>) {
    watch::channel(NetworkState::default())
}
