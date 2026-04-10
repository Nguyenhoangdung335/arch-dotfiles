pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../Config" as Cfg
import "../JSUtils/Logging.js" as Log

Singleton {
  id: root

  property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
  property string socketPath: runtimeDir + "/shell-ricing/shell.sock"

  // Retry properties
  property int maxRetries: 5
  property int baseRetryInterval: 1000
  property real intervalMultiplier: 2.5
  property int retryCount: 0
  property int currentRetryInterval: baseRetryInterval
  property bool isRetrying: false
  property bool isConnected: false

  signal messageReceived(string module, var data)

  function startRetrying() {
    root.isRetrying = true;
    root.retryCount = 0;
    root.currentRetryInterval = root.baseRetryInterval;
    reconnectTimer.interval = root.currentRetryInterval;
    reconnectTimer.start();
  }

  function resolveIncomingEvent(jsonString: string) {
    try {
      Log.info("BackendService: Received event:", jsonString);
      let event = JSON.parse(jsonString);

      let moduleName = event.module;
      if (!moduleName) {
        Log.warn("BackendService: Missing module field in event, defaulting to 'network'");
        moduleName = "network";
      }
      let payload = event.data !== undefined ? event.data : event;

      root.messageReceived(moduleName, payload);
    } catch (e) {
      Log.error("Failed to parse backend event:", e, "\nRaw String:", jsonString);
    }
  }

  function sendRequest(moduleName, actionPayload) {
    if (!socketLoader.item || !socketLoader.item.connected) {
      Log.error("BackendService: Socket not connected!");
      return;
    }

    let payload = {
      "module": moduleName,
      "action": actionPayload
    };
    let jsonString = JSON.stringify(payload) + "\n";
    socketLoader.item.write(jsonString);
    socketLoader.item.flush();
  }

  function load() {
    if (Cfg.Global.isDebug)
      Log.info("BackendService: Loaded");
  }

  Component.onCompleted: {
    if (!socketLoader.item || !socketLoader.item.connected) {
      root.startRetrying();
    }
  }

  Component {
    id: socketComponent

    Socket {
      id: socket

      path: root.socketPath
      connected: true

      parser: SplitParser {
        onRead: chunk => {
          root.resolveIncomingEvent(chunk);
        }
      }

      onConnectionStateChanged: {
        if (connected) {
          Log.info("BackendService: Connected to Rust Backend!");
          root.isConnected = true;
          reconnectTimer.stop();
          executeReconnect.stop();
          root.isRetrying = false;
          root.retryCount = 0;
        } else {
          root.isConnected = false;
          if (!root.isRetrying) {
            Log.warn("BackendService: Unexpectedly disconnected. Starting retry sequence...");
            root.startRetrying();
          }
        }
      }
    }
  }

  Loader {
    id: socketLoader

    sourceComponent: socketComponent
    active: true
  }

  Timer {
    id: reconnectTimer

    interval: root.baseRetryInterval
    repeat: false
    running: false

    onTriggered: {
      if (root.retryCount >= root.maxRetries) {
        Log.error("BackendService: Max retries (" + root.maxRetries + ") reached. Giving up.");
        root.isRetrying = false;
        return;
      }
      root.retryCount += 1;
      root.currentRetryInterval = Math.round(root.currentRetryInterval * root.intervalMultiplier);
      Log.info("BackendService: Retry " + root.retryCount + "/" + root.maxRetries + " — next attempt in " + root.currentRetryInterval + "ms");
      socketLoader.active = false;
      executeReconnect.start();
    }
  }

  Timer {
    id: executeReconnect

    interval: 50
    repeat: false
    running: false

    onTriggered: {
      reconnectTimer.interval = root.currentRetryInterval;
      reconnectTimer.start();
      socketLoader.active = true;
    }
  }
}
