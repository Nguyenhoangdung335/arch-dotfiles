use std::collections::HashMap;

use zbus::proxy;
use zbus::zvariant::{OwnedObjectPath, OwnedValue};

#[proxy(
    default_service = "org.freedesktop.NetworkManager",
    default_path = "/org/freedesktop/NetworkManager",
    interface = "org.freedesktop.NetworkManager"
)]
pub trait NetworkManager {
    #[zbus(property)]
    fn devices(&self) -> zbus::Result<Vec<OwnedObjectPath>>; // ao
    #[zbus(property)]
    fn networking_enabled(&self) -> zbus::Result<bool>; // b
    #[zbus(property)]
    fn wireless_enabled(&self) -> zbus::Result<bool>; // b
    #[zbus(property)]
    fn state(&self) -> zbus::Result<u32>; // u
    #[zbus(property)]
    fn connectivity(&self) -> zbus::Result<u32>; // u
    #[zbus(property)]
    fn active_connections(&self) -> zbus::Result<Vec<OwnedObjectPath>>; // ao

    #[zbus(property)]
    fn set_wireless_enabled(&self, enabled: bool) -> zbus::Result<()>;

    async fn enable(&self, enable: bool) -> zbus::Result<()>;
    async fn activate_connection(
        &self,
        connection: OwnedObjectPath,
        device: OwnedObjectPath,
        specific_object: OwnedObjectPath,
    ) -> zbus::Result<OwnedObjectPath>;
    async fn add_and_activate_connection(
        &self,
        connection: HashMap<String, HashMap<String, OwnedValue>>,
        device: OwnedObjectPath,
        specific_object: OwnedObjectPath,
    ) -> zbus::Result<OwnedObjectPath>;
}

#[proxy(
    default_service = "org.freedesktop.NetworkManager",
    interface = "org.freedesktop.NetworkManager.Device"
)]
pub trait NMDevice {
    #[zbus(property)]
    fn device_type(&self) -> zbus::Result<u32>; // u
    #[zbus(property)]
    fn interface(&self) -> zbus::Result<String>; // s
    #[zbus(property)]
    fn active_connection(&self) -> zbus::Result<OwnedObjectPath>; // o
}

#[proxy(
    default_service = "org.freedesktop.NetworkManager",
    interface = "org.freedesktop.NetworkManager.Device.Wireless"
)]
pub trait NMDeviceWireless {
    #[zbus(property)]
    fn active_access_point(&self) -> zbus::Result<OwnedObjectPath>; // o

    async fn get_all_access_points(&self) -> zbus::Result<Vec<OwnedObjectPath>>;
    async fn request_scan(&self, options: HashMap<String, OwnedValue>) -> zbus::Result<()>;
}

#[proxy(
    default_service = "org.freedesktop.NetworkManager",
    interface = "org.freedesktop.NetworkManager.AccessPoint"
)]
pub trait NMAccessPoint {
    #[zbus(property)]
    fn ssid(&self) -> zbus::Result<Vec<u8>>; // ay
    #[zbus(property)]
    fn strength(&self) -> zbus::Result<u8>; // y
    #[zbus(property)]
    fn hw_address(&self) -> zbus::Result<String>; // s
    #[zbus(property)]
    fn frequency(&self) -> zbus::Result<u16>; // u
    #[zbus(property)]
    fn flags(&self) -> zbus::Result<u32>; // u
    #[zbus(property)]
    fn wpa_flags(&self) -> zbus::Result<u32>; // u
    #[zbus(property)]
    fn rsn_flags(&self) -> zbus::Result<u32>; // u
    #[zbus(property)]
    fn mode(&self) -> zbus::Result<u32>; // u
}

#[proxy(
    default_service = "org.freedesktop.NetworkManager",
    interface = "org.freedesktop.DBus.Properties"
)]
pub trait NMAccessPointProperties {
    async fn get_all(&self, interface_name: &str) -> zbus::Result<HashMap<String, OwnedValue>>;
}

#[proxy(
    default_service = "org.freedesktop.NetworkManager",
    interface = "org.freedesktop.NetworkManager.Connection.Active"
)]
pub trait NMActiveConnection {
    #[zbus(property)]
    fn connection(&self) -> zbus::Result<OwnedObjectPath>; // o
}

#[proxy(
    default_service = "org.freedesktop.NetworkManager",
    default_path = "/org/freedesktop/NetworkManager/Settings",
    interface = "org.freedesktop.NetworkManager.Settings"
)]
pub trait NMSettings {
    #[zbus(property)]
    fn connections(&self) -> zbus::Result<Vec<OwnedObjectPath>>; // ao
    #[zbus(property)]
    fn hostname(&self) -> zbus::Result<String>; // s
}
