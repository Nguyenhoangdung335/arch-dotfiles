import QtQuick
import QtQuick.Effects
import "../Themes" as Th
import "../Config" as Cfg
import "../Services" as Svc

// Compact theme selection menu with Material Design
Rectangle {
    id: root
    
    // Public API
    Svc.ThemeModel {
        id: themeModel
    }
    
    // Dimensions
    implicitWidth: 280
    implicitHeight: contentColumn.implicitHeight + 32
    
    // Glassmorphism styling
    color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.85)
    radius: 16
    border.width: 1
    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)
    
    // Backdrop blur
    layer.enabled: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 0.5
        saturation: 0.3
    }
    
    // Drop shadow
    Rectangle {
        anchors.fill: parent
        anchors.margins: -12
        z: -1
        radius: parent.radius
        color: "#000000"
        opacity: 0.4
    }
    
    Column {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }
        spacing: 12
        
        // Header
        Row {
            width: parent.width
            spacing: 12
            
            Text {
                text: "🎨"
                font.pixelSize: 20
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: "Theme Selector"
                color: Th.Theme.fg
                font.pixelSize: 16
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
        }
        
        // Theme options
        Repeater {
            model: themeModel.model
            
            delegate: Rectangle {
                width: contentColumn.width
                height: 48
                radius: 12
                color: isActive ? Th.Theme.primary : "transparent"
                
                property bool isActive: Cfg.Theme.paletteFamily === model.family && 
                                       Cfg.Theme.paletteVariant === model.variant
                
                border.width: isActive ? 0 : 1
                border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
                
                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Text {
                        text: model.emoji
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        text: model.family + " · " + model.variant
                        color: parent.parent.isActive ? Th.Theme.bg : Th.Theme.fg
                        font.pixelSize: 14
                        font.weight: parent.parent.isActive ? Font.DemiBold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        Th.Theme.setPalette(model.family, model.variant);
                    }
                    
                    onEntered: {
                        if (!parent.isActive) {
                            parent.color = Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05);
                        }
                    }
                    
                    onExited: {
                        if (!parent.isActive) {
                            parent.color = "transparent";
                        }
                    }
                }
                
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
