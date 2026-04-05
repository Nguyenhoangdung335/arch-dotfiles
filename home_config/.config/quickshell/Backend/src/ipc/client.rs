use std::sync::Arc;

use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::net::unix::OwnedWriteHalf;
use tokio::sync::{mpsc, watch};
use tokio::task::JoinSet;

use crate::app::AppContext;
use crate::core::enums::IPCModule;
use crate::modules::network::action::NetworkAction;

#[derive(serde::Deserialize, serde::Serialize, Debug)]
#[serde(tag = "module", content = "action", rename_all = "lowercase")]
pub enum ClientRequest {
    Network(NetworkAction),
}

#[derive(serde::Serialize, serde::Deserialize, Debug)]
pub struct ResponseEvent<T> {
    pub module: IPCModule,
    pub data: T,
}

pub struct IPCClient {
    request_rx: mpsc::Receiver<ResponseEvent<serde_json::Value>>,
    module_forwarder: JoinSet<()>,
    ctx: Arc<AppContext>,
}

impl IPCClient {
    pub async fn new(ctx: Arc<AppContext>) -> anyhow::Result<Self> {
        let (request_tx, request_rx) = mpsc::channel(100);
        let mut client = Self {
            request_rx,
            module_forwarder: JoinSet::new(),
            ctx,
        };
        client
            .attach_module_state_receiver(
                IPCModule::Network,
                request_tx.clone(),
                client.ctx.network_handle.state_rx.clone(),
            )
            .await;

        Ok(client)
    }

    /// Attaches a receiver to the module and forwards any changes to the client.
    ///
    /// This attach a lightweight concurrent task to forward any changes from the attached module
    /// to the IPCClient mpsc channel to be handled.
    ///
    /// # Arguments
    /// * `module` - The module to attach the receiver to.
    /// * `receiver` - The mpsc::Receiver used inside of the module to receive state updates.
    pub async fn attach_module_state_receiver<T>(
        &mut self,
        module: IPCModule,
        request_tx: mpsc::Sender<ResponseEvent<serde_json::Value>>,
        receiver: watch::Receiver<T>,
    ) where
        T: serde::Serialize + Send + Sync + 'static,
    {
        let mut receiver = receiver.clone();
        self.module_forwarder.spawn(async move {
            // Send the current initial state
            let json_result = {
                let state = receiver.borrow();
                serde_json::to_value(&*state)
            };
            if let Ok(json_value) = json_result {
                let response_event = ResponseEvent {
                    module: module.clone(),
                    data: json_value,
                };
                let _ = request_tx.send(response_event).await;
            }

            // Waiting for future changes
            while receiver.changed().await.is_ok() {
                let json_result = {
                    let state = receiver.borrow();
                    serde_json::to_value(&*state)
                };
                if let Ok(json_value) = json_result {
                    let response_event = ResponseEvent {
                        module: module.clone(),
                        data: json_value,
                    };
                    let _ = request_tx.send(response_event).await;
                } else {
                    tracing::error!(module = ?module, "Failed to serialize state");
                }
            }
        });
    }

    pub async fn handle_client(&mut self, stream: tokio::net::UnixStream) -> anyhow::Result<()> {
        let (reader, mut writer) = stream.into_split();
        let mut reader = BufReader::new(reader);
        let mut line = String::new();

        loop {
            tokio::select! {
                result = reader.read_line(&mut line) => {
                    let bytes_read = result?;
                    if bytes_read == 0 { break; } // Client disconnected (socket closed)

                    if let Ok(req) = serde_json::from_str::<ClientRequest>(&line) {
                        handle_request(&req, self.ctx.clone()).await;
                    } else {
                        tracing::error!(line = ?line, "Failed to parse Quickshell request");
                    }
                    line.clear();
                }

                maybe_event = self.request_rx.recv() => {
                    match maybe_event {
                        Some(event) => if send_event(&mut writer, event).await.is_err() {
                            break;
                        },
                        None => break, // All module forwarders dropped
                    }
                }
            }
        }

        Ok(())
    }
}

async fn handle_request(req: &ClientRequest, ctx: Arc<AppContext>) {
    match req {
        ClientRequest::Network(action) => ctx.network_handle.handle_action(action.clone()).await,
    }
}

async fn send_event(
    writer: &mut OwnedWriteHalf,
    event: ResponseEvent<serde_json::Value>,
) -> std::io::Result<()> {
    let mut payload = serde_json::to_vec(&event)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
    payload.push(b'\n');

    tokio::io::AsyncWriteExt::write_all(writer, &payload).await?;
    tokio::io::AsyncWriteExt::flush(writer).await?;
    Ok(())
}
