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

    property var networkState: {
        "is_wireless_enabled": false,
        "wifi_access_points": null,
        "active_connection": null,
        "wifi_device_object_path": null
    }

    signal messageReceived(string module, var data)

    Component {
        id: socketComponent
        Socket {
            id: socket
            path: root.socketPath
            connected: true

            onConnectionStateChanged: {
                if (connected) {
                    Log.info("BackendService: Connected to Rust Backend!");
                    reconnectTimer.stop();
                    root.retryCount = 0;
                    root.currentRetryInterval = root.baseRetryInterval;
                } else if (root.retryCount === 0) {
                    Log.warn("BackendService: Unexpectedly disconnected. Resetting and reconnecting...");
                    root.currentRetryInterval = root.baseRetryInterval;
                    reconnectTimer.interval = root.currentRetryInterval;
                    reconnectTimer.start();

                }
            }

            parser: SplitParser {
                onRead: chunk => { root.resolveIncomingEvent(chunk) };
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
        interval: root.currentRetryInterval
        repeat: false
        running: false
        onTriggered: {
            if (root.retryCount >= root.maxRetries) {
                Log.error("BackendService: Max retries (" + root.maxRetries + ") reached. Giving up.");
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
            socketLoader.active = true;
            reconnectTimer.interval = root.currentRetryInterval;
            reconnectTimer.start();
        }
    }

    Component.onCompleted: {
        if (!socketLoader.item || !socketLoader.item.connected) {
            reconnectTimer.interval = root.currentRetryInterval;
            reconnectTimer.start();
        }
    }

    function resolveIncomingEvent(jsonString) {
        try {
            let event = JSON.parse(jsonString);

            switch (event.module) {
                case "network":
                    root.networkState = event.data;
                    console.log("Network state updated:", JSON.stringify(root.networkState));
                    break;
                case "bluetooth":
                    // Future implementation...
                    break;
                default:
                    console.warn("Unknown module received:", event.module);
                    return;
                }
            root.messageReceived(event.module, event.data);
        } catch (e) {
            console.error("Failed to parse backend event:", e, "\nRaw String:", jsonString);
        }
    }

    function sendRequest(moduleName, actionPayload) {
        if (!socketLoader.item || !socketLoader.item.connected) {
            console.error("BackendService: Socket not connected!");
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
        if (Cfg.Global.isDebug) console.log("BackendService: Loaded");
    }
}
