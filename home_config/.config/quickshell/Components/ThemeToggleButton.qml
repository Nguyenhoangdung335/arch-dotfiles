import QtQuick
import "../Themes" as Th

// Floating theme toggle button with glassmorphism
Rectangle {
    id: root
    
    // Public API
    signal clicked()
    property bool isExpanded: false
    
    // Dimensions
    width: 56
    height: 56
    radius: 28
    
    // Glassmorphism styling
    color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.8)
    border.width: 1
    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)
    
    // Elevation shadow
    Rectangle {
        anchors.fill: parent
        anchors.margins: -8
        z: -1
        radius: parent.radius
        color: "#000000"
        opacity: 0.3
    }
    
    // Icon (palette symbol)
    Text {
        anchors.centerIn: parent
        text: "🎨"
        font.pixelSize: 28
    }
    
    // Hover effect
    scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.05 : 1.0)
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 300 } }
}
