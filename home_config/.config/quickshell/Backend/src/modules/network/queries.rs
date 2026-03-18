use futures::stream::StreamExt;
use tokio::sync::watch::Sender;
use tracing::{error, info};
use zbus::fdo::PropertiesProxy;

use crate::core::enums::NMDeviceType;

use super::proxies::{DeviceProxy, NetworkManagerProxy};
use super::state::NetworkState;

pub struct NetworkQuery {
    sys_bus: zbus::Connection,
    nm_proxy: NetworkManagerProxy<'static>,
    state_tx: Sender<NetworkState>,
}

impl NetworkQuery {
    pub async fn new(
        sys_bus: &zbus::Connection,
        state_tx: Sender<NetworkState>,
    ) -> anyhow::Result<Self> {
        let nm_proxy = NetworkManagerProxy::new(sys_bus).await?;

        let new_query = Self {
            sys_bus: sys_bus.clone(),
            nm_proxy,
            state_tx,
        };
        new_query.spawn_nm_proxy_listener().await?;
        Ok(new_query)
    }

    pub async fn get_wifi_device_object_path(&self) -> anyhow::Result<Option<String>> {
        let devices = self.nm_proxy.devices().await?;
        let mut wifi_device = None;
        for d in devices.into_iter() {
            let device_proxy = DeviceProxy::builder(&self.sys_bus)
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
                state.send_wifi_device_object_path_changed(Some(device.to_string()))
            });
        }

        Ok(object_path_str)
    }

    pub async fn is_wifi_enabled(&self) -> anyhow::Result<bool> {
        Ok(self.nm_proxy.wireless_enabled().await?)
    }

    async fn spawn_nm_proxy_listener(&self) -> anyhow::Result<()> {
        let inner = self.nm_proxy.inner();
        let props_proxy = PropertiesProxy::builder(&self.sys_bus)
            .destination(inner.destination().clone())?
            .path(inner.path().clone())?
            .build()
            .await?;
        let mut props_stream = props_proxy.receive_properties_changed().await?;

        let state_tx = self.state_tx.clone();
        tokio::spawn(async move {
            while let Some(changed_event) = props_stream.next().await {
                match changed_event.args() {
                    Ok(args) => {
                        for (prop_name, value) in args.changed_properties() {
                            match *prop_name {
                                "WirelessEnabled" => {
                                    if let Ok(enabled) = value.try_into() {
                                        state_tx.send_if_modified(|state| {
                                            state.send_is_wireless_enabled_changed(enabled)
                                        });
                                    }
                                }
                                "ActiveConnection" => info!("ActiveConnection changed"),
                                _ => {}
                            }
                        }
                    }
                    Err(e) => error!("Failed to get event args: {:?}", e),
                }
            }
        });

        Ok(())
    }
}
