use tokio::sync::watch::Receiver;
use zbus::zvariant::OwnedObjectPath;

use super::proxies::NetworkManagerProxy;
use super::state::NetworkState;

pub struct NetworkCommand {
    _sys_bus: zbus::Connection,
    nm_proxy: NetworkManagerProxy<'static>,
    _state_rx: Receiver<NetworkState>,
}

impl NetworkCommand {
    pub async fn new(
        sys_bus: &zbus::Connection,
        state_rx: Receiver<NetworkState>,
    ) -> anyhow::Result<Self> {
        let nm_proxy = NetworkManagerProxy::new(sys_bus).await?;
        Ok(Self {
            _sys_bus: sys_bus.clone(),
            nm_proxy,
            _state_rx: state_rx,
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
            let state = self._state_rx.borrow();
            state.wireless_enabled
        };

        self.nm_proxy
            .set_wireless_enabled(!currently_enabled)
            .await?;
        Ok(!currently_enabled)
    }
}
