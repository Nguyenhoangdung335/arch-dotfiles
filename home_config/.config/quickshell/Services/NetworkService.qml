pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "../JSUtils/Logging.js" as Log

Singleton {
  id: root

  property bool isWirelessEnabled: false
  property var activeConnection: null
  property string wifiDeviceObjectPath: "/"
  property ListModel accessPoints: ListModel {}
  property var rawNetworkState: ({})

  function updateNetworkState(data: var) {
    Log.info("NetworkService: Received network state update:", data);

    let newState = Object.assign({}, root.rawNetworkState, data);
    root.rawNetworkState = newState;

    if (data.is_wireless_enabled !== undefined) {
      root.isWirelessEnabled = data.is_wireless_enabled;
    }
    if (data.active_connection !== undefined) {
      root.activeConnection = data.active_connection;
    }
    if (data.wifi_device_object_path !== undefined) {
      root.wifiDeviceObjectPath = data.wifi_device_object_path;
    }
    if (data.wifi_access_points !== undefined && data.wifi_access_points !== null) {
      updateAccessPoints(data.wifi_access_points);
    }
  }

  function updateAccessPoints(newAps: var) {
    if (!newAps)
      return;

    let oldKeys = [];
    for (let i = 0; i < root.accessPoints.count; i++) {
      let ap = root.accessPoints.get(i);
      oldKeys.push((ap.bssid || "") + "_" + (ap.ssid || ""));
    }

    for (let i = 0; i < newAps.length; i++) {
      let newAp = newAps[i];
      let newKey = (newAp.bssid || "") + "_" + (newAp.ssid || "");

      let existingIdx = -1;
      for (let j = i; j < root.accessPoints.count; j++) {
        let ap = root.accessPoints.get(j);
        if (((ap.bssid || "") + "_" + (ap.ssid || "")) === newKey) {
          existingIdx = j;
          break;
        }
      }

      if (existingIdx !== -1) {
        if (existingIdx !== i) {
          root.accessPoints.move(existingIdx, i, 1);
          let movedKey = oldKeys.splice(existingIdx, 1)[0];
          oldKeys.splice(i, 0, movedKey);
        }

        let apObj = root.accessPoints.get(i);
        for (let prop in newAp) {
          if (apObj[prop] !== newAp[prop]) {
            root.accessPoints.setProperty(i, prop, newAp[prop]);
          }
        }
      } else {
        root.accessPoints.insert(i, newAp);
        oldKeys.splice(i, 0, newKey);
      }
    }

    while (root.accessPoints.count > newAps.length) {
      root.accessPoints.remove(root.accessPoints.count - 1, 1);
    }
  }

  function connectToNetwork(ssid: string, password: string) {
    if (!ssid)
      return;
    BackendService.sendRequest("network", {
      "type": "connect",
      "ssid": ssid,
      "password": password || ""
    });
  }

  function disconnectNetwork() {
    BackendService.sendRequest("network", {
      "type": "disconnect"
    });
  }

  function toggleWifi(enabled: bool) {
    BackendService.sendRequest("network", {
      "type": "toggle_wifi",
      "enabled": enabled
    });
  }

  Connections {
    function onMessageReceived(module: string, data: var) {
      if (module === "network") {
        root.updateNetworkState(data);
      }
    }

    target: BackendService
  }
}
