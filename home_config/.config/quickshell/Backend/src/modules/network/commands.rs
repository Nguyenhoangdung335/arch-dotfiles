use std::collections::HashMap;

use tokio::sync::watch::Receiver;
use zbus::zvariant::OwnedObjectPath;

use super::proxies::{NMDeviceWirelessProxy, NetworkManagerProxy};
use super::state::NetworkState;

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

    pub async fn activate_connection(
        &self,
        connection: &str,
        device: &str,
        specific_object: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let connection = OwnedObjectPath::try_from(connection)?;
        let device = OwnedObjectPath::try_from(device)?;
        let specific_object = OwnedObjectPath::try_from(specific_object)?;

        self.nm_proxy
            .activate_connection(connection, device, specific_object)
            .await?;

        Ok(())
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
}
