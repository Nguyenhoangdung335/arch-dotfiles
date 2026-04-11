use futures::StreamExt;
use futures::stream::FuturesUnordered;
use tokio::sync::{mpsc, watch::Sender};
use tracing::{error, warn};

use zbus::zvariant::OwnedObjectPath;

use crate::{
    modules::network::actor::NetworkMessage,
    modules::network::enums::{NMConnectivity, NMDeviceType, NMState},
    modules::network::proxies::{
        NMAccessPointPropertiesProxy, NMDeviceProxy, NMDeviceWirelessProxy, NMSettingsProxy,
        NetworkManagerProxy,
    },
    modules::network::state::{NetworkState, SavedConnection, WifiAccessPoint},
    update_state_if_changed,
    utils::compare::update_if_changed,
};

pub struct NetworkQuery {
    sys_bus: zbus::Connection,
    nm_proxy: NetworkManagerProxy<'static>,
    nm_settings_proxy: NMSettingsProxy<'static>,
    state_tx: Sender<NetworkState>,
    internal_bus_sender: mpsc::Sender<NetworkMessage>,
}

impl NetworkQuery {
    pub async fn new(
        sys_bus: &zbus::Connection,
        state_tx: Sender<NetworkState>,
        internal_bus_sender: mpsc::Sender<NetworkMessage>,
    ) -> anyhow::Result<Self> {
        let nm_proxy = NetworkManagerProxy::new(sys_bus).await?;
        let nm_settings_proxy = NMSettingsProxy::new(sys_bus).await?;

        let new_query = Self {
            sys_bus: sys_bus.clone(),
            nm_proxy,
            nm_settings_proxy,
            state_tx,
            internal_bus_sender,
        };
        Ok(new_query)
    }
    pub async fn get_wifi_device_object_path(&self) -> anyhow::Result<Option<String>> {
        let devices = self.nm_proxy.devices().await?;
        let mut wifi_device = None;
        for d in devices.into_iter() {
            let device_proxy = NMDeviceProxy::builder(&self.sys_bus)
                .path(d.clone())?
                .build()
                .await?;

            match device_proxy.device_type().await {
                Ok(t) => {
                    if t == NMDeviceType::WiFi as u32 {
                        wifi_device = Some(d.clone());
                        break;
                    }
                }
                Err(e) => error!("Failed to get device type: {:?}", e),
            }
        }

        let mut object_path_str: Option<String> = None;
        if let Some(device) = wifi_device {
            object_path_str = Some(device.to_string());
            self.state_tx.send_if_modified(|state| {
                // state.send_wifi_device_object_path_changed(Some(device.to_string()))
                update_if_changed(&mut state.wifi_device_object_path, Some(device.to_string()))
            });
        }

        Ok(object_path_str)
    }

    pub async fn is_wifi_enabled(&self) -> anyhow::Result<bool> {
        let is_wifi_enabled = self.nm_proxy.wireless_enabled().await?;
        self.state_tx.send_if_modified(|state| {
            update_if_changed(&mut state.wireless_enabled, is_wifi_enabled)
        });
        Ok(is_wifi_enabled)
    }

    pub async fn is_networking_enabled(&self) -> anyhow::Result<bool> {
        let is_networking_enabled = self.nm_proxy.networking_enabled().await?;
        self.state_tx.send_if_modified(|state| {
            update_if_changed(&mut state.networking_enabled, is_networking_enabled)
        });
        Ok(is_networking_enabled)
    }

    pub async fn sync_current_state(&self) -> anyhow::Result<()> {
        match self.is_wifi_enabled().await {
            Ok(enabled) if !enabled => {
                warn!("Wifi is not enabled");
                return Ok(());
            }
            Err(e) => {
                error!("Failed to check if wifi is enabled: {:?}", e);
                return Ok(());
            }
            _ => {}
        }

        match self.is_networking_enabled().await {
            Ok(enabled) if !enabled => {
                warn!("Networking is not enabled");
                return Ok(());
            }
            Err(e) => {
                error!("Failed to check if networking is enabled: {:?}", e);
                return Ok(());
            }
            _ => {}
        }

        self.get_nm_state().await?;
        self.get_nm_connectivity().await?;
        self.get_hostname().await?;

        let wifi_device_object_path = match self.get_wifi_device_object_path().await {
            Ok(Some(path)) => {
                self.internal_bus_sender
                    .send(NetworkMessage::RegisterNMDeviceWirelessEvent(
                        path.to_string(),
                    ))
                    .await?;
                path
            }
            Ok(None) => {
                warn!("No wifi device object path found");
                return Ok(());
            }
            Err(e) => {
                error!("Failed to get wifi device object path: {:?}", e);
                return Ok(());
            }
        };
        // Skipping on sending the wifi_device_object_path because
        // it is already sent inside query method already.

        let sys_bus = self.sys_bus.clone();
        let state_tx = self.state_tx.clone();

        tokio::spawn(async move {
            if let Ok(wifi_access_points) =
                match NMDeviceWirelessProxy::builder(&sys_bus).path(wifi_device_object_path) {
                    Ok(p) => p.build().await,
                    Err(e) => {
                        error!("Failed to create NMDeviceWirelessProxy: {:?}", e);
                        return;
                    }
                }
                && let Ok(object_paths) = wifi_access_points.get_all_access_points().await
            {
                let aps = Self::fetch_multiple_access_points_with_bus(&sys_bus, object_paths).await;
                state_tx.send_if_modified(|state| {
                    update_if_changed(&mut state.wifi_access_points, aps)
                });
            }
        });

        Ok(())
    }

    // region: Fetch single access point logic

    pub async fn fetch_single_access_point(
        &self,
        path: OwnedObjectPath,
    ) -> Option<WifiAccessPoint> {
        Self::fetch_single_access_point_with_bus(&self.sys_bus, path).await
    }

    async fn fetch_single_access_point_with_bus(
        sys_bus: &zbus::Connection,
        path: OwnedObjectPath,
    ) -> Option<WifiAccessPoint> {
        let proxy = match NMAccessPointPropertiesProxy::new(sys_bus, path.clone()).await {
            Ok(p) => p,
            Err(e) => {
                error!(path = %path, err = %e, "Failed to create NMAccessPointPropertiesProxy");
                return None;
            }
        };

        let properties = match proxy
            .get_all("org.freedesktop.NetworkManager.AccessPoint")
            .await
        {
            Ok(props) => props,
            Err(e) => {
                error!(path = %path, err = %e, "Failed to get AP properties");
                return None;
            }
        };

        match WifiAccessPoint::try_from_properties_with_path(properties, &path) {
            Ok(ap) if ap.ssid.is_empty() => {
                warn!(path = %path, "AP has no SSID");
                None
            }
            Ok(ap) => Some(ap),
            Err(e) => {
                error!(path = %path, err = %e, "Failed to parse WifiAccessPoint properties");
                None
            }
        }
    }

    // endregion

    // region: Fetch multiple access points logic

    pub async fn fetch_multiple_access_points(
        &self,
        paths: Vec<OwnedObjectPath>,
    ) -> Vec<WifiAccessPoint> {
        Self::fetch_multiple_access_points_with_bus(&self.sys_bus, paths).await
    }

    async fn fetch_multiple_access_points_with_bus(
        sys_bus: &zbus::Connection,
        paths: Vec<OwnedObjectPath>,
    ) -> Vec<WifiAccessPoint> {
        let mut futures_tasks = FuturesUnordered::new();

        for path in paths {
            let bus = sys_bus.clone();
            futures_tasks
                .push(async move { Self::fetch_single_access_point_with_bus(&bus, path).await });
        }

        let mut aps = Vec::new();
        while let Some(result) = futures_tasks.next().await {
            if let Some(ap) = result {
                aps.push(ap);
            }
        }
        // Sort APs by strength descending
        aps.sort_by(|a, b| b.strength.cmp(&a.strength));

        aps
    }

    // endregion

    #[allow(irrefutable_let_patterns)]
    pub async fn get_hostname(&self) -> anyhow::Result<String> {
        let hostname = self.nm_settings_proxy.hostname().await?;
        update_state_if_changed!(self.state_tx, hostname.clone(), hostname);
        Ok(hostname)
    }

    pub async fn get_saved_connections(&self) -> anyhow::Result<Vec<String>> {
        // TODO: Implement when needed
        Ok(Vec::new())
    }

    pub async fn get_nm_state(&self) -> anyhow::Result<NMState> {
        let state = self.nm_proxy.state().await?;
        update_state_if_changed!(self.state_tx, state, state);
        Ok(state.into())
    }

    pub async fn get_nm_connectivity(&self) -> anyhow::Result<NMConnectivity> {
        let connectivity = self.nm_proxy.connectivity().await?;
        update_state_if_changed!(self.state_tx, connectivity, connectivity);
        Ok(connectivity.into())
    }
}
