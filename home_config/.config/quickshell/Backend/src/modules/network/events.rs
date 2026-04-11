use std::time::Duration;

use tokio::sync::mpsc;
use tokio::sync::watch;
use tokio_util::sync::CancellationToken;
use tracing::debug;
use tracing::{Instrument, error, info};
use zbus::zvariant::OwnedObjectPath;

use crate::{
    core::dbus_listener::DbusPropertyListener,
    modules::network::actor::NetworkMessage,
    modules::network::proxies::{NMDeviceWirelessProxy, NetworkManagerProxy},
    modules::network::state::NetworkState,
    proxy_span, update_state_if_changed,
    utils::compare::update_if_changed,
};

pub struct NetworkEvent {
    sys_bus: zbus::Connection,
    cancel_token: CancellationToken,
    register: DbusPropertyListener,
    state_tx: watch::Sender<NetworkState>,
    internal_bus_sender: mpsc::Sender<NetworkMessage>,
}

impl NetworkEvent {
    pub async fn new(
        sys_bus: &zbus::Connection,
        state_tx: watch::Sender<NetworkState>,
        internal_bus_sender: mpsc::Sender<NetworkMessage>,
        cancel_token: CancellationToken,
    ) -> anyhow::Result<Self> {
        let register = DbusPropertyListener::new(sys_bus).await?;
        Ok(Self {
            sys_bus: sys_bus.clone(),
            register,
            state_tx,
            internal_bus_sender,
            cancel_token,
        })
    }

    pub async fn register_nm_event(&mut self) -> anyhow::Result<()> {
        let (destination, path) = {
            let nm_proxy = NetworkManagerProxy::new(&self.sys_bus).await?;
            let inner = nm_proxy.inner();
            (inner.destination().clone(), inner.path().clone())
        };

        let state_tx = self.state_tx.clone();
        let internal_bus_sender = self.internal_bus_sender.clone();

        self.register
            .register(
                self.cancel_token.child_token(),
                destination.clone(),
                path.clone(),
                "org.freedesktop.NetworkManager",
                move |prop_name, value| {
                    let state_tx = state_tx.clone();
                    let internal_bus_sender = internal_bus_sender.clone();
                    let cloned_prop_name = prop_name.clone();

                    async move {
                        debug!("Received NM event: {}", prop_name);
                        match prop_name.as_str() {
                            "WirelessEnabled" => {
                                update_state_if_changed!(state_tx, value, wireless_enabled)
                            }
                            "NetworkingEnabled" => {
                                update_state_if_changed!(state_tx, value, networking_enabled)
                            }
                            "State" => update_state_if_changed!(state_tx, value, state),
                            "Connectivity" => {
                                update_state_if_changed!(state_tx, value, connectivity)
                            }
                            "Devices" => {
                                info!("Devices changed");
                                if let Err(e) = internal_bus_sender
                                    .send(NetworkMessage::DevicesChanged)
                                    .await
                                {
                                    error!("Failed to send DevicesChanged message: {:?}", e);
                                }
                            }
                            _ => {}
                        }
                    }
                    .instrument(proxy_span!(
                        "nm_event",
                        destination,
                        path,
                        "org.freedesktop.NetworkManager",
                        cloned_prop_name
                    ))
                },
            )
            .await?;

        Ok(())
    }

    pub async fn register_nm_device_wireless_event(
        &mut self,
        wifi_device_object_path: String,
    ) -> anyhow::Result<()> {
        let (destination, path, interface) = {
            let proxy = NMDeviceWirelessProxy::builder(&self.sys_bus)
                .path(wifi_device_object_path)?
                .build()
                .await?;
            let inner = proxy.inner();
            (
                inner.destination().clone(),
                inner.path().clone(),
                inner.interface().clone(),
            )
        };

        // 1. Setup debounce channel for AccessPoints
        let (ap_tx, ap_rx) = watch::channel::<Option<Vec<OwnedObjectPath>>>(None);

        // 2. Spawn the debouncer background task
        tokio::spawn(Self::debounce_access_points_task(
            ap_rx,
            self.internal_bus_sender.clone(),
            self.cancel_token.child_token(),
        ));

        let internal_bus_sender = self.internal_bus_sender.clone();
        self.register
            .register_or_replace(
                self.cancel_token.child_token(),
                destination.clone(),
                path.clone(),
                interface.as_str(),
                move |prop_name, value| {
                    let ap_tx = ap_tx.clone();
                    let internal_bus_sender = internal_bus_sender.clone();
                    let cloned_prop_name = prop_name.clone();

                    async move {
                        match prop_name.as_str() {
                            "ActiveAccessPoint" => {
                                if let Ok(ap_path) = OwnedObjectPath::try_from(value) {
                                    if let Err(e) = internal_bus_sender.send(NetworkMessage::ActiveAccessPointChanged(ap_path)).await {
                                        error!("Failed to send ActiveAccessPointChanged: {:?}", e);
                                    }
                                } else {
                                    error!("Failed to convert ActiveAccessPoint value to OwnedObjectPath");
                                }
                            }
                            "AccessPoints" => {
                                if let Ok(paths) = <Vec<OwnedObjectPath>>::try_from(value) {
                                    let _ = ap_tx.send(Some(paths));
                                } else {
                                    error!("Failed to convert AccessPoints to Vec<OwnedObjectPath>");
                                }
                            }
                            _ => {}
                        }
                    }
                    .instrument(proxy_span!(
                        "nm_wireless_device_event",
                        destination,
                        path,
                        "org.freedesktop.NetworkManager.Device.Wireless",
                        cloned_prop_name
                    ))
                },
            )
            .await?;

        Ok(())
    }

    // region --- Extracted Helpers ---

    async fn debounce_access_points_task(
        mut ap_rx: watch::Receiver<Option<Vec<OwnedObjectPath>>>,
        internal_bus_sender: mpsc::Sender<NetworkMessage>,
        cancel_token: CancellationToken,
    ) {
        loop {
            tokio::select! {
                _ = cancel_token.cancelled() => break,
                res = ap_rx.changed() => {
                    if res.is_err() { break; }

                    // Wait 500ms for rapid burst of events to settle
                    tokio::time::sleep(Duration::from_millis(500)).await;

                    // Grab latest value ignoring intermediates
                    let paths_opt = ap_rx.borrow_and_update().clone();

                    if let Some(paths) = paths_opt
                        && let Err(e) = internal_bus_sender.send(NetworkMessage::AccessPointsChanged(paths)).await {
                            error!("Failed to send AccessPointsChanged: {:?}", e);
                        }
                }
            }
        }
    }
}
