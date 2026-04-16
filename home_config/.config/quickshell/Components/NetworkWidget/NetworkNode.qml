pragma ComponentBehavior: Bound

import QtQuick
import "../../Themes" as Th

Rectangle {
  id: root

  property real targetX: 0
  property real targetY: 0
  property bool opened: false
  property string ssid: ""
  property int strength: 0
  property bool connected: false
  property bool isCurrent: false
  property bool isFocused: false
  readonly property bool isHovered: hoverHandler.hovered
  property bool keyboardNavActive: false
  property bool effectivelyHovered: isHovered && !keyboardNavActive

  signal clicked

  width: isCurrent ? 50 : (isFocused || effectivelyHovered ? 45 : 40)
  height: width
  radius: width / 2
  color: isCurrent ? Th.Theme.accent : (isFocused || effectivelyHovered ? Th.Theme.primary : Th.Theme.surface)
  border.color: isCurrent ? Qt.rgba(Th.Theme.accent.r, Th.Theme.accent.g, Th.Theme.accent.b, 0.8) : (isFocused || effectivelyHovered ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.8) : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2))
  border.width: isFocused || effectivelyHovered ? 3 : 2
  scale: isFocused || effectivelyHovered ? 1.2 : 1.0
  x: targetX
  y: targetY

  Behavior on width {
    NumberAnimation {
      duration: 150
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: 150
    }
  }
  Behavior on opacity {
    NumberAnimation {
      duration: 300
    }
  }

  HoverHandler {
    id: hoverHandler

    cursorShape: Qt.PointingHandCursor
  }

  MouseArea {
    id: clickArea

    anchors.fill: parent

    onClicked: root.clicked()
  }

  Text {
    anchors.top: parent.bottom
    anchors.topMargin: 4
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.ssid
    color: Th.Theme.fg
    font.pixelSize: 12
    visible: root.opened
  }
}
