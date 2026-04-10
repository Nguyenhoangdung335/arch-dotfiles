import QtQuick

import "../Themes" as Th

// Generic glass-style card component
Rectangle {
  id: root

  // Public API
  property real glassOpacity: 0.75
  property real borderOpacity: 0.3
  property int elevation: 2

  // Default styling
  color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, glassOpacity)
  radius: 16
  border.width: 1
  border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, borderOpacity)

  // Drop shadow for elevation
  Rectangle {
    anchors.fill: parent
    anchors.margins: -root.elevation * 4
    z: -1
    radius: parent.radius
    color: "#000000"
    opacity: 0.15 * root.elevation

    Behavior on opacity {
      NumberAnimation {
        duration: 200
      }
    }
  }
}
