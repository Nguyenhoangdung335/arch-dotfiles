use futures::StreamExt;
use tokio::task::JoinSet;
use tokio_util::sync::CancellationToken;
use tracing::{error, info};
use zbus::names::BusName;
use zbus::zvariant::{ObjectPath, OwnedValue};

pub struct DbusPropertyListener {
    sys_bus: zbus::Connection,
    handles: tokio::task::JoinSet<()>,
}

impl DbusPropertyListener {
    pub async fn new(sys_bus: &zbus::Connection) -> anyhow::Result<Self> {
        Ok(Self {
            sys_bus: sys_bus.clone(),
            handles: JoinSet::new(),
        })
    }

    pub async fn register<F, Fut>(
        &mut self,
        cancel_token: CancellationToken,
        destination: BusName<'static>,
        path: ObjectPath<'static>,
        interface: &'static str,
        handler: F,
    ) -> anyhow::Result<()>
    where
        F: Fn(String, OwnedValue) -> Fut + Send + Sync + 'static,
        Fut: Future<Output = ()> + Send + 'static,
    {
        let properties_proxy = zbus::fdo::PropertiesProxy::builder(&self.sys_bus)
            .destination(destination)?
            .path(path)?
            .build()
            .await?;
        let mut props_stream = properties_proxy.receive_properties_changed().await?;
        let cancel_token = cancel_token.clone();

        self.handles.spawn(async move {
            loop {
                tokio::select! {
                    Some(changed_event) = props_stream.next() => {
                    if let Ok(args) = changed_event.args() {
                        if args.interface_name() != interface {
                            continue;
                        }

                        for (prop_name, value) in args.changed_properties() {
                            handler(prop_name.to_string(), {
                                match OwnedValue::try_from(value) {
                                    Ok(owned_value) => owned_value,
                                    Err(e) => {
                                        error!("Failed to convert value to owned value: {}", e);
                                        continue;
                                    }
                                }
                            })
                            .await;
                        }
                    }
                    },
                    _ = cancel_token.cancelled() => {
                        info!("Cancelled");
                        break;
                    },
                }
            }
        });

        Ok(())
    }
}
