#[async_trait::async_trait]
pub trait Module {
    type State: Clone + serde::Serialize + Send + Sync + 'static;
    type Action: serde::de::DeserializeOwned + Send;

    async fn sync_state(&self) -> anyhow::Result<()>;
    async fn handle_action(&self, action: Self::Action);
    fn state_receiver(&self) -> tokio::sync::watch::Receiver<Self::State>;
}
