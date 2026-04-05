use std::collections::HashMap;

use futures::StreamExt;
use tokio::task::JoinSet;
use tokio_util::sync::CancellationToken;
use tracing::{Instrument, error, info, instrument, warn};
use zbus::names::BusName;
use zbus::zvariant::{ObjectPath, OwnedObjectPath, OwnedValue};

type ListenerKey = (OwnedObjectPath, String);

pub struct DbusPropertyListener {
    sys_bus: zbus::Connection,
    handles: tokio::task::JoinSet<()>,
    cancel_token_map: HashMap<ListenerKey, CancellationToken>, // (path, interface) -> cancel_token
}

impl DbusPropertyListener {
    pub async fn new(sys_bus: &zbus::Connection) -> anyhow::Result<Self> {
        Ok(Self {
            sys_bus: sys_bus.clone(),
            handles: JoinSet::new(),
            cancel_token_map: HashMap::new(),
        })
    }

    // #[instrument(skip(self, cancel_token, handler))]
    pub async fn register<F, Fut>(
        &mut self,
        cancel_token: CancellationToken,
        destination: BusName<'_>,
        path: ObjectPath<'_>,
        interface: &str,
        handler: F,
    ) -> anyhow::Result<()>
    where
        F: Fn(String, OwnedValue) -> Fut + Send + Sync + 'static,
        Fut: Future<Output = ()> + Send + 'static,
    {
        let properties_proxy = zbus::fdo::PropertiesProxy::builder(&self.sys_bus)
            .destination(destination)?
            .path(path.clone())?
            .build()
            .await?;
        let mut props_stream = properties_proxy.receive_properties_changed().await?;
        self.cancel_token_map.insert(
            (path.clone().into(), interface.to_string()),
            cancel_token.clone(),
        );
        let cancel_token = cancel_token.clone();

        let interface = interface.to_string();
        self.handles.spawn(async move {
            loop {
                tokio::select! {
                    Some(changed_event) = props_stream.next() => {
                    if let Ok(args) = changed_event.args() {
                        if args.interface_name() != interface.as_str() {
                            continue;
                        }

                        for (prop_name, value) in args.changed_properties() {
                            handler(prop_name.to_string(), {
                                match OwnedValue::try_from(value) {
                                    Ok(owned_value) => owned_value,
                                    Err(e) => {
                                        error!(error = %e, "Failed to convert value to owned value");
                                        continue;
                                    }
                                }
                            })
                            .await;
                        }
                    }
                    },
                    _ = cancel_token.cancelled() => {
                        info!("DBus Listener cancelled");
                        break;
                    },
                }
            }
        }.in_current_span(),
        );

        Ok(())
    }

    #[instrument(skip(self, cancel_token, handler))]
    pub async fn register_or_replace<F, Fut>(
        &mut self,
        cancel_token: CancellationToken,
        destination: BusName<'_>,
        path: ObjectPath<'_>,
        interface: &str,
        handler: F,
    ) -> anyhow::Result<()>
    where
        F: Fn(String, OwnedValue) -> Fut + Send + Sync + 'static,
        Fut: Future<Output = ()> + Send + 'static,
    {
        let owned_path: OwnedObjectPath = path.clone().into();
        let owned_interface = interface.to_string();

        if let Some(cancel_token) = self
            .cancel_token_map
            .remove(&(owned_path.clone(), owned_interface.clone()))
        {
            cancel_token.cancel();
            info!("Cancelled DBus Listener");
        }
        self.cancel_token_map
            .insert((owned_path, owned_interface), cancel_token.clone());

        let properties_proxy = zbus::fdo::PropertiesProxy::builder(&self.sys_bus)
            .destination(destination)?
            .path(path)?
            .build()
            .await?;
        let mut props_stream = properties_proxy.receive_properties_changed().await?;
        let cancel_token = cancel_token.clone();

        let interface = interface.to_string();
        self.handles.spawn(async move {
            loop {
                tokio::select! {
                    Some(changed_event) = props_stream.next() => {
                    if let Ok(args) = changed_event.args() {
                        if args.interface_name() != interface.as_str() {
                            continue;
                        }

                        for (prop_name, value) in args.changed_properties() {
                            handler(prop_name.to_string(), {
                                match OwnedValue::try_from(value) {
                                    Ok(owned_value) => owned_value,
                                    Err(e) => {
                                        error!(error = %e, "Failed to convert value to owned value");
                                        continue;
                                    }
                                }
                            })
                            .await;
                        }
                    }
                    },
                    _ = cancel_token.cancelled() => {
                        info!("DBus Listener cancelled");
                        break;
                    },
                }
            }
        }.in_current_span(),
        );

        Ok(())
    }

    #[allow(dead_code)]
    #[instrument(skip(self))]
    pub fn unregister(&mut self, path: ObjectPath<'_>, interface: &str) {
        if let Some(cancel_token) = self
            .cancel_token_map
            .remove(&(path.into(), interface.to_string()))
        {
            cancel_token.cancel();
            info!("Cancelled DBus Listener");
        } else {
            warn!("No DBus Listener found");
        }
    }
}
