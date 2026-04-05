import QtQuick

Rectangle {
    id: root
    
    signal clicked()
    
    // Properties for positioning and logic
    property real targetX: 0
    property real targetY: 0
    property bool opened: false
    property string ssid: ""
    property int strength: 0
    property bool isCurrent: false
    property bool isFocused: false
    property bool isHovered: false

    width: isCurrent ? 50 : (isFocused || isHovered ? 45 : 40)
    height: width
    radius: width / 2
    color: isCurrent ? "#A3BE8C" : (isFocused || isHovered ? "#5E81AC" : "#4C566A")
    border.color: isCurrent ? "#8FBCBB" : (isFocused || isHovered ? "#81A1C1" : "#3B4252")
    border.width: isFocused || isHovered ? 3 : 2
    scale: isFocused || isHovered ? 1.2 : 1.0

    // Update opacity based on opened state
    // Note: opacity handling might be overridden or multiplied by the parent (delegate binding)
    // We'll let GraphLayout bind to a property or we can just bind opacity here.
    // Actually GraphLayout binds opacity directly. We should remove the binding here to avoid conflict.
    
    // Set position targets
    x: opened ? targetX : parent.width / 2 - width / 2
    y: opened ? targetY : parent.height / 2 - height / 2

    // Behaviors for smooth spring transitions
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

    Behavior on scale {
        NumberAnimation {
            duration: 150
        }
    }
    
    Behavior on width {
        NumberAnimation { duration: 150 }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: root.isHovered = hovered
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        onClicked: root.clicked()
    }

    // Label showing SSID
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
