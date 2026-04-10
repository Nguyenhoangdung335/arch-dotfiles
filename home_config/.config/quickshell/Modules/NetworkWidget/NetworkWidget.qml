pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../../Themes" as Th
import "../../Config" as Cfg
import "../../Components/NetworkWidget" as NetComp
import "../../Services" as Svc

PanelWindow {
  id: root

  property bool opened: false
  property bool isAnimating: slideAnim.running

  // Widget dimensions
  readonly property int widgetWidth: 650
  readonly property int widgetHeight: 550

  // Toggle Functions
  function toggle() {
    opened = !opened;
  }

  function open() {
    opened = true;
  }

  function close() {
    opened = false;
  }

  visible: root.opened || root.isAnimating
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  aboveWindows: true
  focusable: root.opened

  // Fixed geometry to prevent Hyprland layer size jumps
  implicitWidth: root.widgetWidth
  implicitHeight: root.widgetHeight

  mask: Region {
    item: contentWrapper
  }

  anchors {
    top: true
    right: true
  }

  // Add margin to push it below the status bar, assuming status bar is at the top
  margins {
    top: 40
    right: 10
  }

  Item {
    id: contentWrapper

    property bool animationRunning: slideAnim.running

    anchors.left: parent.left
    anchors.right: parent.right
    height: root.widgetHeight

    // Slide animation (drawer from top)
    y: root.opened ? 0 : -root.widgetHeight
    clip: false
    enabled: root.opened || root.isAnimating

    Behavior on y {
      NumberAnimation {
        id: slideAnim

        duration: 400
        easing.type: Easing.OutQuint
      }
    }

    // Background
    Rectangle {
      id: blurBackground

      anchors.fill: parent
      radius: 12
      color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.85)
      border.width: 1
      border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)
      layer.enabled: true

      layer.effect: MultiEffect {
        blurEnabled: true
        blur: root.opened ? 0.5 : 0.0
        saturation: 1.2
      }
    }

    // Content
    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 16

      Text {
        text: "Network Graph"
        color: Th.Theme.fg
        font.pixelSize: 18
        font.bold: true
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
      }

      // The Graph
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        NetComp.GraphLayout {
          id: graphLayout

          anchors.fill: parent
          opened: root.opened
          focus: root.opened
          accessPointsModel: Svc.NetworkService.accessPoints
        }
      }
    }
  }

  // Keyboard navigation
  Item {
    anchors.fill: parent
    focus: root.opened

    Shortcut {
      sequence: Cfg.KeyBinds.closeWidget
      enabled: root.opened

      onActivated: root.close()
    }
  }

  // GlobalShortcut
  GlobalShortcut {
    name: Cfg.KeyBinds.toggleNetworkWidget
    description: "Toggle network widget"

    onPressed: root.toggle()
  }

  // IPC Handler
  IpcHandler {
    function toggle(): void {
      root.toggle();
    }

    function open(): void {
      root.open();
    }

    function close(): void {
      root.close();
    }

    target: "network"
  }
}
