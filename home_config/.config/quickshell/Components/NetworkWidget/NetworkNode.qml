pragma ComponentBehavior: Bound

import QtQuick

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
  property bool isHovered: false

  signal clicked

  width: isCurrent ? 50 : (isFocused || isHovered ? 45 : 40)
  height: width
  radius: width / 2
  color: isCurrent ? "#A3BE8C" : (isFocused || isHovered ? "#5E81AC" : "#4C566A")
  border.color: isCurrent ? "#8FBCBB" : (isFocused || isHovered ? "#81A1C1" : "#3B4252")
  border.width: isFocused || isHovered ? 3 : 2
  scale: isFocused || isHovered ? 1.2 : 1.0
  x: opened ? targetX : parent.width / 2 - width / 2
  y: opened ? targetY : parent.height / 2 - height / 2

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
  Behavior on x {
    SpringAnimation {
      spring: 2.0
      damping: 0.15
    }
  }
  Behavior on y {
    SpringAnimation {
      spring: 2.0
      damping: 0.15
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

    onHoveredChanged: root.isHovered = hoverHandler.hovered
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
    color: "#ECEFF4"
    font.pixelSize: 12
    visible: root.opened
  }
}
