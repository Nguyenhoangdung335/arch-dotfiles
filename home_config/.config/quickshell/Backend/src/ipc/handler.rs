use std::sync::Arc;

use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::net::unix::OwnedWriteHalf;

use crate::app::AppContext;
use crate::core::enums::IPCModule;
use crate::modules::network::action::NetworkAction;

#[derive(serde::Deserialize, Debug)]
#[serde(tag = "module", content = "action", rename_all = "lowercase")]
pub enum ClientRequest {
    Network(NetworkAction),
}

#[derive(serde::Serialize, Debug)]
struct Event<'a, T> {
    module: IPCModule,
    data: &'a T,
}

pub async fn handle_client(
    stream: tokio::net::UnixStream,
    ctx: Arc<AppContext>,
) -> anyhow::Result<()> {
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);
    let mut line = String::new();

    let mut network_rx = ctx.network.state_rx.clone();

    let initial_state = network_rx.borrow().clone();
    send_event(&mut writer, IPCModule::Network, &initial_state).await?;

    loop {
        tokio::select! {
        result = reader.read_line(&mut line) => {
            let bytes_read = result?;
            if bytes_read == 0 { break; } // Client disconnected (socket closed)

            if let Ok(req) = serde_json::from_str::<ClientRequest>(&line) {
                handle_request(&req, ctx.clone()).await;
            } else {
                tracing::error!("Failed to parse Quickshell request: {}", line);
            }
            line.clear();
        }

        Ok(_) = network_rx.changed() => {
            let new_state = network_rx.borrow().clone();
            if send_event(&mut writer, IPCModule::Network, &new_state).await.is_err() {
                break; // Socket error, drop client
            }
        }

        // More modules can be added here
        // Ok(_) = bluetooth_rx.changed() => { ... }
        }
    }
    Ok(())
}

async fn handle_request(req: &ClientRequest, ctx: Arc<AppContext>) {
    match req {
        ClientRequest::Network(action) => ctx.network.handle_action(action).await,
    }
}

async fn send_event<T: serde::Serialize>(
    writer: &mut OwnedWriteHalf,
    module: IPCModule,
    data: &T,
) -> std::io::Result<()> {
    let event = Event { module, data };

    let mut payload = serde_json::to_vec(&event)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
    payload.push(b'\n');

    let mut w = writer;
    tokio::io::AsyncWriteExt::write_all(&mut w, &payload).await?;
    tokio::io::AsyncWriteExt::flush(&mut w).await?;
    Ok(())
}
