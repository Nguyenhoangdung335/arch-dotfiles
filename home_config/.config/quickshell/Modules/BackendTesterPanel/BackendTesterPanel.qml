pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

import "../../Themes" as Th
import "../../Components" as Comp
import "../../Components/BackendTesterPanel" as InterComp
import "../../Config" as Cfg
import "../../Services" as Svc

// Toggleable, resizable backend IPC debugger window
Window {
  id: root

  property bool isOpen: false
  property int activeTab: 0
  property string selectedModule: "network"
  property string lastSendPayload: ""
  property bool moduleMenuOpen: false

  // ── State source per module ───────────────────────────────────────
  readonly property var moduleStateSources: ({
      "network": Svc.NetworkService.rawNetworkState
      // "bluetooth": Svc.BluetoothService.rawState
    })
  readonly property var currentStateData: moduleStateSources[root.selectedModule] || ({})

  // ── Known actions per module (for autocomplete / quick buttons) ──
  readonly property var knownActions: ({
      "network": [
        {
          name: "toggle_wifi",
          label: "Toggle WiFi",
          argsHint: ""
        },
        {
          name: "scan_wifi",
          label: "Scan WiFi",
          argsHint: ""
        },
        {
          name: "connect",
          label: "Connect",
          argsHint: '{"ssid": "MyNetwork"}'
        },
        {
          name: "get_wifi_device_object_path",
          label: "WiFi Device Path",
          argsHint: ""
        },
        {
          name: "get_current_state",
          label: "Get Current Latest State",
          argsHint: ""
        },
        {
          name: "get_hostname",
          label: "Get Hostname",
          argsHint: ""
        },
        {
          name: "get_saved_connections",
          label: "Get SavedConnections",
          argsHint: ""
        }
      ]
      // "bluetooth": [ ... ]
    })
  property bool autoScroll: true

  // ── Toggle functions ──────────────────────────────────────────────
  function toggle() {
    isOpen = !isOpen;
  }

  function open() {
    isOpen = true;
  }

  function close() {
    isOpen = false;
  }

  // ── Log an outgoing message ───────────────────────────────────────
  function logOutgoing(module, payload) {
    let jsonStr = (typeof payload === "string") ? payload : JSON.stringify(payload, null, 2);
    sentLog.append({
      "timestamp": new Date().toLocaleTimeString(),
      "module": module,
      "payload": jsonStr
    });
  }

  // ── Send request and log it ───────────────────────────────────────
  function sendAndLog(module, actionPayload) {
    Svc.BackendService.sendRequest(module, actionPayload);
    logOutgoing(module, {
      "module": module,
      "action": actionPayload
    });
  }

  // ── Window Configuration ──────────────────────────────────────────
  visible: root.isOpen
  width: 520
  height: 700
  minimumWidth: 350
  minimumHeight: 400
  color: "transparent"

  // Center on screen on first show
  x: Screen.width / 2 - width / 2
  y: Screen.height / 2 - height / 2
  title: "Backend Tester"

  // ── Visibility / Focus management ─────────────────────────────────
  onIsOpenChanged: {
    if (isOpen) {
      requestActivate();
    }
  }

  // ── Available modules (extend when adding bluetooth, audio, etc.) ─
  ListModel {
    id: moduleModel

    ListElement {
      name: "network"
      label: "Network"
    }
    // ListElement { name: "bluetooth"; label: "Bluetooth" }
  }

  // ── Message log models ─────────────────────────────────────────────
  ListModel {
    id: sentLog
  }

  ListModel {
    id: recvLog
  }

  // ── Keyboard shortcuts ────────────────────────────────────────────
  Shortcut {
    sequence: Cfg.KeyBinds.closeWidget
    enabled: root.isOpen

    onActivated: root.close()
  }

  // ── GlobalShortcut (Hyprland integration) ─────────────────────────
  GlobalShortcut {
    name: Cfg.KeyBinds.toggleBackendTester
    description: "Toggle backend tester panel"

    onPressed: root.toggle()
  }

  // ── IPC Handler ───────────────────────────────────────────────────
  IpcHandler {
    function toggle(): void {
      root.toggle();
    }

    function open(): void {
      root.isOpen = true;
    }

    function close(): void {
      root.isOpen = false;
    }

    target: "backendTesterPanel"
  }

  // ── Listen to BackendService messages for the log tab ─────────────
  Connections {
    function onMessageReceived(module, data) {
      recvLog.append({
        "timestamp": new Date().toLocaleTimeString(),
        "module": module,
        "payload": JSON.stringify(data, null, 2)
      });
    }

    target: Svc.BackendService
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.moduleMenuOpen
    propagateComposedEvents: true

    onClicked: root.moduleMenuOpen = false
  }

  // ══════════════════════════════════════════════════════════════════
  //  VISUAL CONTENT
  // ══════════════════════════════════════════════════════════════════

  // ── Main container ────────────────────────────────────────────────
  Rectangle {
    id: container

    anchors.fill: parent
    color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.92)
    radius: 12
    border.width: 1
    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.12)

    // ── Content ───────────────────────────────────────────────────
    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 0
      spacing: 0

      // ══════════════════════════════════════════════════════════
      //  HEADER
      // ══════════════════════════════════════════════════════════
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.5)
        radius: 12

        // Only bottom corners rounded (top handled by container)
        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 12
          color: parent.color
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          spacing: 8

          Text {
            text: "Backend Tester"
            color: Th.Theme.fg
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
          }

          // Module selector
          Rectangle {
            Layout.preferredWidth: moduleSelectorText.width + 32
            Layout.preferredHeight: 28
            color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)
            radius: 14
            border.width: 1
            border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)

            Text {
              id: moduleSelectorText

              anchors.centerIn: parent
              text: root.selectedModule + " ▾"
              color: Th.Theme.primary
              font.pixelSize: 12
              font.weight: Font.Medium
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor

              onClicked: root.moduleMenuOpen = !root.moduleMenuOpen
            }

            // Custom dropdown
            Column {
              id: moduleDropdown

              anchors.top: parent.bottom
              anchors.topMargin: 4
              anchors.right: parent.right
              z: 100
              visible: root.moduleMenuOpen

              Repeater {
                id: moduleRepeater

                model: moduleModel

                delegate: Rectangle {
                  id: moduleItemArea

                  required property var modelData

                  width: 120
                  height: 30
                  radius: 6
                  color: moduleArea.containsMouse ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.15) : Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.95)

                  Text {
                    anchors.centerIn: parent
                    text: moduleItemArea.modelData.label
                    color: Th.Theme.fg
                    font.pixelSize: 13
                  }

                  MouseArea {
                    id: moduleArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                      root.selectedModule = moduleRepeater.model.name;
                      root.moduleMenuOpen = false;
                    }
                  }
                }
              }
            }
          }

          // Connection status indicator
          RowLayout {
            spacing: 6

            Rectangle {
              Layout.preferredWidth: 8
              Layout.preferredHeight: 8
              radius: 4
              color: Svc.BackendService.isConnected ? Th.Theme.success : Th.Theme.error

              SequentialAnimation on opacity {
                running: !Svc.BackendService.isConnected
                loops: Animation.Infinite

                NumberAnimation {
                  from: 1.0
                  to: 0.3
                  duration: 800
                }

                NumberAnimation {
                  from: 0.3
                  to: 1.0
                  duration: 800
                }
              }
            }

            Text {
              text: Svc.BackendService.isConnected ? "Connected" : "Disconnected"
              color: Svc.BackendService.isConnected ? Th.Theme.success : Th.Theme.error
              font.pixelSize: 11
              font.weight: Font.Medium
            }
          }
        }
      }

      // ══════════════════════════════════════════════════════════
      //  TAB BAR
      // ══════════════════════════════════════════════════════════
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        Layout.topMargin: 8
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        color: "transparent"

        RowLayout {
          anchors.fill: parent
          spacing: 6

          Comp.SidebarTabButton {
            text: "State"
            isActive: root.activeTab === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            onClicked: root.activeTab = 0
          }

          Comp.SidebarTabButton {
            text: "Actions"
            isActive: root.activeTab === 1
            Layout.fillWidth: true
            Layout.fillHeight: true

            onClicked: root.activeTab = 1
          }

          Comp.SidebarTabButton {
            text: "Builder"
            isActive: root.activeTab === 2
            Layout.fillWidth: true
            Layout.fillHeight: true

            onClicked: root.activeTab = 2
          }

          Comp.SidebarTabButton {
            text: "Log"
            isActive: root.activeTab === 3
            Layout.fillWidth: true
            Layout.fillHeight: true

            onClicked: root.activeTab = 3
          }
        }
      }

      // Separator
      Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.preferredHeight: 1
        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)
      }

      // ══════════════════════════════════════════════════════════
      //  TAB CONTENT
      // ══════════════════════════════════════════════════════════
      StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 12
        currentIndex: root.activeTab

        // ─────────────────────────────────────────────────────
        // TAB 0: STATE VIEWER
        // ─────────────────────────────────────────────────────
        InterComp.StateTab {
          stateData: root.currentStateData
          moduleName: root.selectedModule
        }

        // ─────────────────────────────────────────────────────
        // TAB 1: QUICK ACTIONS
        // ─────────────────────────────────────────────────────
        InterComp.ActionsTab {
          selectedModule: root.selectedModule
          knownActions: root.knownActions

          onSendAction: function (module, actionPayload) {
            root.sendAndLog(module, actionPayload);
          }
        }

        // ─────────────────────────────────────────────────────
        // TAB 2: REQUEST BUILDER
        // ─────────────────────────────────────────────────────
        InterComp.BuilderTab {
          selectedModule: root.selectedModule
          knownActions: root.knownActions

          onSendRequest: function (module, actionPayload) {
            root.sendAndLog(module, actionPayload);
          }
        }

        // ─────────────────────────────────────────────────────
        // TAB 3: MESSAGE LOG
        // ─────────────────────────────────────────────────────
        InterComp.LogTab {
          sentModel: sentLog
          recvModel: recvLog
          autoScroll: root.autoScroll

          onAutoScrollToggled: value => root.autoScroll = value
          onClearLog: {
            sentLog.clear();
            recvLog.clear();
          }
        }
      }
    }
  }
}
