pub mod action;
pub mod commands;
pub mod enums;
pub mod events;
pub mod proxies;
pub mod queries;
pub mod state;

use self::action::NetworkAction;
use self::commands::NetworkCommand;
use self::events::NetworkEvent;
use self::proxies::{AccessPointProxy, DeviceWirelessProxy};
use self::queries::NetworkQuery;
use self::state::{NetworkState, WifiAccessPoint, create_network_state};
use futures::StreamExt;
use futures::stream::FuturesUnordered;
use tokio::sync::watch::{Receiver, Sender};
use tracing::{error, info};

pub struct NetworkModule {
    sys_bus: zbus::Connection,
    pub query: NetworkQuery,
    pub command: NetworkCommand,
    pub event: NetworkEvent,
    pub state_rx: Receiver<NetworkState>,
    pub state_tx: Sender<NetworkState>,
}

impl NetworkModule {
    pub async fn new(sys_bus: &zbus::Connection) -> anyhow::Result<Self> {
        let (state_tx, state_rx) = create_network_state();
        let (query, command, event) = tokio::try_join!(
            NetworkQuery::new(sys_bus, state_tx.clone()),
            NetworkCommand::new(sys_bus, state_rx.clone()),
            NetworkEvent::new(sys_bus, state_tx.clone(), cancel_token.child_token()),
        )?;

        let module = Self {
            sys_bus: sys_bus.clone(),
            query,
            command,
            event,
            state_rx,
            state_tx,
        };
        module.sync_current_state().await?;

        Ok(module)
    }

    pub async fn sync_current_state(&self) -> anyhow::Result<()> {
        let is_wifi_enabled = self.query.is_wifi_enabled().await?;
        self.state_tx
            .send_if_modified(|state| state.send_is_wireless_enabled_changed(is_wifi_enabled));

        let wifi_device_object_path = self.query.get_wifi_device_object_path().await?;
        if wifi_device_object_path.is_none() {
            error!("No wifi device object path found");
            return Ok(());
        }
        // Skipping on sending the device_object_path because
        // it is already sent inside query method already.

        let sys_bus = self.sys_bus.clone();
        let state_tx = self.state_tx.clone();

        tokio::spawn(async move {
            if let Ok(wifi_access_points) = DeviceWirelessProxy::builder(&sys_bus)
                .path(wifi_device_object_path.unwrap())
                .unwrap()
                .build()
                .await
            {
                let mut futures_tasks = FuturesUnordered::new();
                if let Ok(object_paths) = wifi_access_points.get_all_access_points().await {
                    for path in object_paths {
                        let sys_bus = sys_bus.clone();
                        futures_tasks.push(async move {
                            let ap_proxy = match AccessPointProxy::builder(&sys_bus)
                                .path(path.clone())
                                .unwrap()
                                .build()
                                .await
                            {
                                Ok(proxy) => proxy,
                                Err(e) => {
                                    error!("Skipping AP {}: {:?}", path, e);
                                    return None;
                                }
                            };

                            let (ssid_res, strength_res, hw_address_res) = tokio::join!(
                                ap_proxy.ssid(),
                                ap_proxy.strength(),
                                ap_proxy.hw_address()
                            );
                            let (ssid, strength, hw_address) =
                                match (ssid_res, strength_res, hw_address_res) {
                                    (Ok(ssid), Ok(strength), Ok(hw_address)) => {
                                        if ssid.is_empty() {
                                            return None;
                                        }
                                        (ssid, strength, hw_address)
                                    }
                                    _ => return None,
                                };

                            Some(WifiAccessPoint {
                                ssid: String::from_utf8_lossy(&ssid).to_string(),
                                strength,
                                hw_address,
                                object_path: path.to_string(),
                            })
                        });
                    }

                    let mut aps: Vec<WifiAccessPoint> = Vec::new();
                    while let Some(result) = futures_tasks.next().await {
                        if let Some(ap) = result {
                            aps.push(ap);
                        }
                    }

                    state_tx.send_if_modified(|state| state.send_wifi_access_points_changed(aps));
                }
            }
        });

        Ok(())
    }

    pub async fn handle_action(&self, action: &NetworkAction) {
        match action {
            NetworkAction::ToggleWifi => {
                info!("Toggling wifi");

                match self.command.toggle_wifi().await {
                    Ok(enabled) => {
                        info!("Successfully toggled wifi to {}", enabled);
                    }
                    Err(e) => error!("Failed to toggle wifi: {}", e),
                };
            }
            NetworkAction::ScanWifi => {
                info!("Scanning for networks");
            }
            NetworkAction::Connect { ssid } => {
                info!("Connecting to {}", ssid);
                match self.command.activate_connection("", "", "").await {
                    Ok(_) => info!("Successfully connected to {}", ssid),
                    Err(e) => error!("Failed to connect to {}: {}", ssid, e),
                };
            }
            NetworkAction::GetWifiDeviceObjectPath => {
                info!("Getting wifi device object path");
                match self.query.get_wifi_device_object_path().await {
                    Ok(_) => {
                        info!("Successfully got wifi device object path");
                    }
                    Err(e) => error!("Failed to get wifi device object path: {}", e),
                };
            }
        }
    }
}
