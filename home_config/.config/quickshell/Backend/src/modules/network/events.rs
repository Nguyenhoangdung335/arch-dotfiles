use tokio::sync::watch::Sender;
use tokio_util::sync::CancellationToken;
use tracing::{debug, info};

use crate::core::dbus_listener::DbusPropertyListener;

use super::proxies::NetworkManagerProxy;
use super::state::NetworkState;

pub struct NetworkEvent {
    sys_bus: zbus::Connection,
    cancel_token: CancellationToken,
    register: DbusPropertyListener,
    state_tx: Sender<NetworkState>,
}

impl NetworkEvent {
    pub async fn new(
        sys_bus: &zbus::Connection,
        state_tx: Sender<NetworkState>,
        cancel_token: CancellationToken,
    ) -> anyhow::Result<Self> {
        let register = DbusPropertyListener::new(sys_bus).await?;
        let mut nm_event = Self {
            sys_bus: sys_bus.clone(),
            register,
            state_tx,
            cancel_token,
        };
        nm_event.register_nm_event().await?;
        Ok(nm_event)
    }

    pub async fn register_nm_event(&mut self) -> anyhow::Result<()> {
        let (destination, path) = {
            let nm_proxy = NetworkManagerProxy::new(&self.sys_bus).await?;
            let inner_nm_proxy = nm_proxy.inner();
            (
                inner_nm_proxy.destination().clone(),
                inner_nm_proxy.path().clone(),
            )
        };

        let state_tx = self.state_tx.clone();
        self.register
            .register(
                self.cancel_token.clone(),
                destination,
                path,
                "org.freedesktop.NetworkManager",
                move |prop_name, value| {
                    let state_tx = state_tx.clone();
                    async move {
                        debug!(
                            "Handling property changed event: {:?} - {:?}",
                            prop_name, value
                        );
                        match prop_name.as_str() {
                            "WirelessEnabled" => {
                                if let Ok(enabled) = <bool>::try_from(value) {
                                    state_tx.send_if_modified(|state| {
                                        state.send_wireless_enabled_changed(enabled)
                                    });
                                }
                            }
                            "ActiveConnection" => info!("ActiveConnection changed"),
                            _ => {}
                        }
                    }
                },
            )
            .await?;

        Ok(())
    }
}
