## Creation flow

```
[main.rs] -> AppContext::new -> NetworkModule::new
    |           |
    |------> [ipc::server::start]
                |
             Create socket path
                |
             For each client connect to the socket path,
             create a new IPC client handling task (via tokio::spawn)
                |
             [ipc::handler::handle_client]
                |
             [tokio::select! between client requests, and state updates]

```
