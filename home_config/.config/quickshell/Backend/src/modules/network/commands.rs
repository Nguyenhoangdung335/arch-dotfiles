use std::collections::HashMap;

use tokio::sync::watch::Receiver;
use zbus::zvariant::OwnedObjectPath;

use crate::{
    modules::network::proxies::{NMDeviceWirelessProxy, NetworkManagerProxy},
    modules::network::state::NetworkState,
};

pub struct NetworkCommand {
    sys_bus: zbus::Connection,
    nm_proxy: NetworkManagerProxy<'static>,
    state_rx: Receiver<NetworkState>,
}

impl NetworkCommand {
    pub async fn new(
        sys_bus: &zbus::Connection,
        state_rx: Receiver<NetworkState>,
    ) -> anyhow::Result<Self> {
        let nm_proxy = NetworkManagerProxy::new(sys_bus).await?;
        Ok(Self {
            sys_bus: sys_bus.clone(),
            nm_proxy,
            state_rx,
        })
    }

    pub async fn toggle_wifi(&self) -> anyhow::Result<bool> {
        let currently_enabled = {
            let state = self.state_rx.borrow();
            state.wireless_enabled
        };

        self.nm_proxy
            .set_wireless_enabled(!currently_enabled)
            .await?;
        Ok(!currently_enabled)
    }

    pub async fn request_scan(&self) -> anyhow::Result<()> {
        let wifi_device_object_path = {
            let state_rx = self.state_rx.borrow();
            match state_rx.wifi_device_object_path.clone() {
                Some(path) => path,
                None => return Err(anyhow::anyhow!("No wifi device object path found")),
            }
        };

        let wifi_device_proxy = NMDeviceWirelessProxy::builder(&self.sys_bus)
            .path(wifi_device_object_path)?
            .build()
            .await?;
        wifi_device_proxy.request_scan(HashMap::new()).await?;
        Ok(())
    }

    pub async fn connect_to_network(
        &self,
        ssid: &str,
        password: Option<&str>,
    ) -> anyhow::Result<()> {
        let (saved_conn_path, wifi_device_path, ap_path, secure) = {
            let state = self.state_rx.borrow();
            Self::resolve_connection_params(&state, ssid)?
        };

        if saved_conn_path.is_none() && secure {
            match password {
                None | Some("") => {
                    return Err(anyhow::anyhow!("Password required for secured network"));
                }
                Some(p) if p.trim().is_empty() => {
                    return Err(anyhow::anyhow!("Password cannot be empty"));
                }
                Some(p) if p.len() < 8 => {
                    return Err(anyhow::anyhow!(
                        "Password must be at least 8 characters long"
                    ));
                }
                _ => {}
            }
        }

        let wifi_device_obj = OwnedObjectPath::try_from(wifi_device_path)?;
        let ap_obj = OwnedObjectPath::try_from(ap_path)?;

        if let Some(conn_path) = saved_conn_path {
            self.nm_proxy
                .activate_connection(
                    OwnedObjectPath::try_from(conn_path)?,
                    wifi_device_obj,
                    ap_obj,
                )
                .await?;
        } else {
            use zbus::zvariant::{OwnedValue, Value};
            let mut connection_settings = HashMap::new();

            let mut conn_map = HashMap::new();
            conn_map.insert(
                "type".to_string(),
                OwnedValue::try_from(Value::from("802-11-wireless")).unwrap(),
            );
            conn_map.insert(
                "id".to_string(),
                OwnedValue::try_from(Value::from(ssid)).unwrap(),
            );
            connection_settings.insert("connection".to_string(), conn_map);

            let mut wifi_map = HashMap::new();
            let ssid_bytes = ssid.as_bytes().to_vec();
            wifi_map.insert(
                "ssid".to_string(),
                OwnedValue::try_from(Value::from(ssid_bytes)).unwrap(),
            );
            connection_settings.insert("802-11-wireless".to_string(), wifi_map);

            if let Some(pwd) = password {
                let mut sec_map = HashMap::new();
                sec_map.insert(
                    "key-mgmt".to_string(),
                    OwnedValue::try_from(Value::from("wpa-psk")).unwrap(),
                );
                sec_map.insert(
                    "psk".to_string(),
                    OwnedValue::try_from(Value::from(pwd)).unwrap(),
                );
                connection_settings.insert("802-11-wireless-security".to_string(), sec_map);
            }

            self.nm_proxy
                .add_and_activate_connection(connection_settings, wifi_device_obj, ap_obj)
                .await?;
        }

        Ok(())
    }

    fn resolve_connection_params(
        state: &NetworkState,
        ssid: &str,
    ) -> anyhow::Result<(Option<String>, String, String, bool)> {
        let saved_conn_path = state
            .saved_connections
            .iter()
            .filter(|c| c.ssid == ssid)
            .max_by_key(|c| c.timestamp)
            .map(|c| c.object_path.clone());

        let wifi_device_path = state
            .wifi_device_object_path
            .clone()
            .ok_or_else(|| anyhow::anyhow!("No wifi device object path found"))?;

        let ap = state.wifi_access_points.iter().find(|ap| ap.ssid == ssid);

        let ap_path = ap
            .map(|ap| ap.object_path.clone())
            .unwrap_or_else(|| String::from("/"));
        let secure = ap.map(|ap| ap.secure).unwrap_or(false);

        Ok((saved_conn_path, wifi_device_path, ap_path, secure))
    }
}

#[cfg(test)]
#[path = "commands_tests.rs"]
mod commands_tests;
