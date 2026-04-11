use tokio::sync::{mpsc, watch};
use tokio_util::sync::CancellationToken;
use tracing::{debug, error, info};
use zbus::zvariant::OwnedObjectPath;

use crate::{
    modules::network::{
        action::NetworkAction, commands::NetworkCommand, events::NetworkEvent,
        queries::NetworkQuery, state::NetworkState,
    },
    utils::compare::update_if_changed,
};

#[derive(Debug)]
pub enum NetworkMessage {
    Action(NetworkAction),
    DevicesChanged,
    SyncCurrentState,
    RegisterNMDeviceWirelessEvent(String),
    ActiveAccessPointChanged(OwnedObjectPath),
    AccessPointsChanged(Vec<OwnedObjectPath>),
}

pub struct NetworkModuleHandle {
    internal_bus_sender: mpsc::Sender<NetworkMessage>,
    pub state_rx: watch::Receiver<NetworkState>,
    pub join_handle: tokio::sync::Mutex<Option<tokio::task::JoinHandle<()>>>,
}

impl NetworkModuleHandle {
    pub async fn handle_action(&self, action: NetworkAction) {
        let _ = self
            .internal_bus_sender
            .send(NetworkMessage::Action(action))
            .await;
    }
}

pub struct NetworkActor {
    cancel_token: CancellationToken,
    query: NetworkQuery,
    command: NetworkCommand,
    event: NetworkEvent,
    internal_bus_receiver: mpsc::Receiver<NetworkMessage>,
    internal_bus_sender: mpsc::Sender<NetworkMessage>,
    state_tx: watch::Sender<NetworkState>,
}

impl NetworkActor {
    pub async fn spawn(
        sys_bus: &zbus::Connection,
        cancel_token: CancellationToken,
    ) -> anyhow::Result<NetworkModuleHandle> {
        let (state_tx, state_rx) = NetworkState::create_state_watcher();
        let (internal_bus_sender, internal_bus_receiver) = mpsc::channel(100);
        let (query, command, mut event) = tokio::try_join!(
            NetworkQuery::new(sys_bus, state_tx.clone(), internal_bus_sender.clone()),
            NetworkCommand::new(sys_bus, state_rx.clone()),
            NetworkEvent::new(
                sys_bus,
                state_tx.clone(),
                internal_bus_sender.clone(),
                cancel_token.child_token()
            ),
        )?;
        match event.register_nm_event().await {
            Ok(_) => info!("Successfully registered NM event"),
            Err(e) => {
                error!(error = ?e, "Failed to register NM event");
                return Err(e);
            }
        };

        let actor = Self {
            cancel_token: cancel_token.clone(),
            query,
            command,
            event,
            internal_bus_receiver,
            internal_bus_sender: internal_bus_sender.clone(),
            state_tx,
        };

        let join_handle = tokio::spawn(async move {
            actor.run().await;
        });

        internal_bus_sender
            .send(NetworkMessage::SyncCurrentState)
            .await?;

        Ok(NetworkModuleHandle {
            internal_bus_sender,
            state_rx,
            join_handle: tokio::sync::Mutex::new(Some(join_handle)),
        })
    }

    async fn run(mut self) {
        loop {
            tokio::select! {
                Some(msg) = self.internal_bus_receiver.recv() => {
                    debug!(msg = ?msg, "Received internal bus message");
                    match msg {
                        NetworkMessage::SyncCurrentState => match self.query.sync_current_state().await {
                            Ok(_) => info!("Successfully synced current state"),
                            Err(e) => error!(err = ?e, "Failed to sync current state"),
                        }
                        NetworkMessage::DevicesChanged => {
                            let wifi_device_object_path = match self.query.get_wifi_device_object_path().await {
                                Ok(Some(path)) => path,
                                Ok(None) => {
                                    error!("No wifi device object path found");
                                    return;
                                }
                                Err(e) => {
                                    error!("Failed to get wifi device object path: {:?}", e);
                                    return;
                                }
                            };
                            self.internal_bus_sender.send(NetworkMessage::RegisterNMDeviceWirelessEvent(wifi_device_object_path)).await.unwrap_or_else(|e| {
                                error!("Failed to send RegisterNMDeviceWirelessEvent message: {:?}", e)
                            });
                        }
                        NetworkMessage::Action(action) => self.handle_action(action).await,
                        NetworkMessage::RegisterNMDeviceWirelessEvent(wifi_device_object_path) => match self.event.register_nm_device_wireless_event(wifi_device_object_path).await {
                                Ok(_) => info!("Successfully registered NMDeviceWireless event"),
                                Err(e) => error!("Failed to register NMDeviceWireless event: {:?}", e),
                            }
                        NetworkMessage::ActiveAccessPointChanged(path) => {
                            if let Some(ap) = self.query.fetch_single_access_point(path).await {
                                self.state_tx.send_if_modified(|state| {
                                    update_if_changed(&mut state.active_access_point, Some(ap))
                                });
                            }
                        }
                        NetworkMessage::AccessPointsChanged(paths) => {
                            let aps = self.query.fetch_multiple_access_points(paths).await;
                            self.state_tx.send_if_modified(|state| {
                                update_if_changed(&mut state.wifi_access_points, aps)
                            });
                        }
                    }
                },
                _ = self.cancel_token.cancelled() => {
                    info!("Shutdown signal received, exiting network actor...");
                    break;
                }
            }
        }
    }

    // region: Actors handlers functions

    async fn handle_action(&self, action: NetworkAction) {
        match action {
            NetworkAction::ToggleWifi => {
                info!("Toggling wifi");

                match self.command.toggle_wifi().await {
                    Ok(enabled) => info!("Successfully toggled wifi to {}", enabled),
                    Err(e) => error!("Failed to toggle wifi: {}", e),
                };
            }
            NetworkAction::ScanWifi => {
                info!("Scanning for networks");
                match self.command.request_scan().await {
                    Ok(_) => info!("Successfully scanned for networks"),
                    Err(e) => error!("Failed to scan for networks: {}", e),
                };
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
                    Ok(_) => info!("Successfully got wifi device object path"),
                    Err(e) => error!("Failed to get wifi device object path: {}", e),
                };
            }
            NetworkAction::GetCurrentState => {
                info!("Getting current network state");
                self.state_tx.send_modify(|_| {});
                info!("Successfully got current network state");
            }
            NetworkAction::GetHostname => {
                info!("Getting hostname");
                match self.query.get_hostname().await {
                    Ok(_) => info!("Successfully got hostname"),
                    Err(e) => error!("Failed to get hostname: {}", e),
                };
            }
            NetworkAction::GetSavedConnections => {
                info!("Getting connections");
                match self.query.get_saved_connections().await {
                    Ok(_) => info!("Successfully got connections"),
                    Err(e) => error!("Failed to get connections: {}", e),
                };
            }
        }
    }

    // endregion
}
