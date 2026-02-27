import QtQuick
import QtQuick.Effects

// Generic glassmorphism card component
Rectangle {
    id: root
    
    // Public API
    property real glassOpacity: 0.75
    property real blurRadius: 32
    property real borderOpacity: 0.3
    property int elevation: 2
    
    // Default styling
    color: Qt.rgba(0, 0, 0, glassOpacity)
    radius: 16
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, borderOpacity)
    
    // Backdrop blur effect (if supported)
    layer.enabled: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 0.4
        saturation: 0.2
    }
    
    // Drop shadow for elevation
    Rectangle {
        anchors.fill: parent
        anchors.margins: -elevation * 4
        z: -1
        radius: parent.radius
        color: "#000000"
        opacity: 0.15 * elevation
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
