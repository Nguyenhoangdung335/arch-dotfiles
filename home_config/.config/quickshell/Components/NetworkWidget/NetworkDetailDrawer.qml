pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Themes" as Th

Rectangle {
  id: root

  property bool opened: false
  property var networkData: null

  signal closeRequested
  signal connectRequested(string ssid)

  width: 200
  color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.95)
  border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)
  border.width: 1
  radius: 8
  x: opened ? parent.width - width : parent.width

  Behavior on x {
    NumberAnimation {
      duration: 300
      easing.type: Easing.OutCubic
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    RowLayout {
      Layout.fillWidth: true

      Text {
        text: root.networkData ? root.networkData.ssid : "Network Details"
        color: Th.Theme.fg
        font.pixelSize: 16
        font.bold: true
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Button {
        text: "\u2715"
        implicitWidth: 24
        implicitHeight: 24

        background: Rectangle {
          color: "transparent"
        }
        contentItem: Text {
          text: parent.text
          color: Th.Theme.fg
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }

        onClicked: root.closeRequested()
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)
    }

    GridLayout {
      columns: 2
      Layout.fillWidth: true
      rowSpacing: 8
      columnSpacing: 12

      Text {
        text: "Signal:"
        color: Th.Theme.fg
        opacity: 0.7
      }

      Text {
        text: root.networkData ? root.networkData.strength + "%" : "-"
        color: Th.Theme.fg
      }

      Text {
        text: "Security:"
        color: Th.Theme.fg
        opacity: 0.7
      }

      Text {
        text: root.networkData && root.networkData.security ? root.networkData.security : "—"
        color: Th.Theme.fg
      }

      Text {
        text: "Freq:"
        color: Th.Theme.fg
        opacity: 0.7
      }

      Text {
        text: root.networkData && root.networkData.freq ? root.networkData.freq : "—"
        color: Th.Theme.fg
      }
    }

    Item {
      Layout.fillHeight: true
    }

    Button {
      text: root.networkData && root.networkData.connected ? "Disconnect" : "Connect"
      Layout.fillWidth: true

      background: Rectangle {
        color: Qt.rgba(Th.Theme.accent.r, Th.Theme.accent.g, Th.Theme.accent.b, 0.8)
        radius: 4
      }
      contentItem: Text {
        text: parent.text
        color: Th.Theme.bg
        horizontalAlignment: Text.AlignHCenter
        font.bold: true
      }

      onClicked: {
        if (root.networkData) {
          root.connectRequested(root.networkData.ssid);
        }
      }
    }
  }
}
