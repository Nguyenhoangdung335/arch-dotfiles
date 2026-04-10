pragma ComponentBehavior: Bound

import QtQuick.Effects
import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property Item sourceNode: null
  property Item targetNode: null
  property bool active: sourceNode !== null && targetNode !== null && targetNode.opacity > 0
  property real startX: sourceNode ? sourceNode.x + sourceNode.width / 2 : 0
  property real startY: sourceNode ? sourceNode.y + sourceNode.height / 2 : 0
  property real endX: targetNode ? targetNode.x + targetNode.width / 2 : 0
  property real endY: targetNode ? targetNode.y + targetNode.height / 2 : 0

  visible: active
  opacity: active ? 1.0 : 0.0
  anchors.fill: parent
  z: 0

  Behavior on opacity {
    NumberAnimation {
      duration: 300
      easing.type: Easing.InOutQuad
    }
  }

  Shape {
    id: edgeShape

    anchors.fill: parent
    layer.enabled: true

    layer.effect: MultiEffect {
      blurEnabled: true
      blur: 0.2
      saturation: 1.5
    }

    ShapePath {
      strokeWidth: 6
      strokeColor: Qt.rgba(136 / 255, 192 / 255, 208 / 255, 0.4)
      fillColor: "transparent"
      joinStyle: ShapePath.RoundJoin
      capStyle: ShapePath.RoundCap
      startX: root.startX
      startY: root.startY

      PathLine {
        x: root.endX
        y: root.endY
      }
    }

    ShapePath {
      strokeWidth: 2
      strokeColor: "#88C0D0"
      fillColor: "transparent"
      joinStyle: ShapePath.RoundJoin
      capStyle: ShapePath.RoundCap
      startX: root.startX
      startY: root.startY

      PathLine {
        x: root.endX
        y: root.endY
      }
    }
  }
}
