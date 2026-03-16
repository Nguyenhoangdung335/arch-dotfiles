pub mod action;
pub mod commands;
pub mod proxies;
pub mod queries;
pub mod state;

use self::action::NetworkAction;
use self::commands::NetworkCommand;
use self::proxies::{AccessPointProxy, DeviceWirelessProxy};
use self::queries::NetworkQuery;
use self::state::{NetworkState, WifiAccessPoint, create_network_state};
use tokio::sync::watch::{Receiver, Sender};

pub struct NetworkModule {
    sys_bus: zbus::Connection,
    pub query: NetworkQuery,
    pub command: NetworkCommand,
    pub state_rx: Receiver<NetworkState>,
    pub state_tx: Sender<NetworkState>,
}

impl NetworkModule {
    pub async fn new(sys_bus: &zbus::Connection) -> anyhow::Result<Self> {
        let (state_tx, state_rx) = create_network_state();
        let query = NetworkQuery::new(sys_bus, state_tx.clone()).await?;
        let command = NetworkCommand::new(sys_bus, state_rx.clone()).await?;

        let module = Self {
            sys_bus: sys_bus.clone(),
            query,
            command,
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
            eprintln!("No wifi device object path found");
            return Ok(());
        }
        self.state_tx.send_if_modified(|state| {
            state.send_wifi_device_object_path_changed(wifi_device_object_path.clone())
        });

        let sys_bus = self.sys_bus.clone();
        let state_tx = self.state_tx.clone();

        tokio::spawn(async move {
            if let Ok(wifi_access_points) = DeviceWirelessProxy::builder(&sys_bus)
                .path(wifi_device_object_path.unwrap())
                .unwrap()
                .build()
                .await
            {
                let mut aps: Vec<WifiAccessPoint> = Vec::new();
                if let Ok(object_paths) = wifi_access_points.get_all_access_points().await {
                    for path in object_paths {
                        let ap_proxy = AccessPointProxy::builder(&sys_bus)
                            .path(path.clone())
                            .unwrap()
                            .build()
                            .await
                            .unwrap();
                        let ssid = ap_proxy.ssid().await.unwrap();
                        let strength = ap_proxy.strength().await.unwrap();
                        aps.push(WifiAccessPoint {
                            ssid: String::from_utf8_lossy(&ssid).to_string(),
                            strength,
                            object_path: path.to_string(),
                        });
                    }
                }

                state_tx.send_if_modified(|state| state.send_wifi_access_points_changed(Some(aps)));
            }
        });

        // TODO: Comment logic for now, intended to spawn some kind of async task
        // or thread to get wifi access points object paths and get properties of
        // each access point

        /* let wifi_device_proxy = DeviceWirelessProxy::builder(&self.sys_bus)
            .path(wifi_device_object_path.unwrap())?
            .build()
            .await?;

        let access_points = wifi_device_proxy.get_all_access_points().await?;
        state.wifi_access_points = {
            let access_points: Vec<String> =
                access_points.iter().map(|ap| ap.to_string()).collect();
            Some(access_points)
        }; */

        Ok(())
    }

    pub async fn handle_action(&self, action: &NetworkAction) {
        match action {
            NetworkAction::ToggleWifi => {
                println!("Toggling wifi");

                match self.command.toggle_wifi().await {
                    Ok(enabled) => {
                        println!("Successfully toggled wifi to {}", enabled);
                    }
                    Err(e) => eprintln!("Failed to toggle wifi: {}", e),
                };
            }
            NetworkAction::ScanWifi => {
                println!("Scanning for networks");
            }
            NetworkAction::Connect { ssid } => {
                println!("Connecting to {}", ssid);
                match self.command.activate_connection("", "", "").await {
                    Ok(_) => {
                        println!("Successfully connected to {}", ssid);
                    }
                    Err(e) => eprintln!("Failed to connect to {}: {}", ssid, e),
                };
            }
            NetworkAction::GetWifiDeviceObjectPath => {
                println!("Getting wifi device object path");
                match self.query.get_wifi_device_object_path().await {
                    Ok(_) => {
                        println!("Successfully got wifi device object path");
                    }
                    Err(e) => eprintln!("Failed to get wifi device object path: {}", e),
                };
            }
        }
    }
}
