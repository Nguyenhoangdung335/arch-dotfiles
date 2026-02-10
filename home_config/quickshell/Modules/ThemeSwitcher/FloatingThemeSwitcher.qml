import QtQuick
import Quickshell
import "../../Components"

// Floating theme switcher with toggle button and expandable menu
PanelWindow {
    id: root
    
    // Window properties
    width: toggleButton.width
    height: toggleButton.height
    color: "transparent"
    
    // Positioning (bottom-right corner with padding)
    anchors {
        right: true
        bottom: true
    }
    
    margins {
        right: 24
        bottom: 24
    }

    // Layer shell properties (Quickshell handles this for PanelWindow)
    // layer: Quickshell.Layer.Overlay 
    // ^ PanelWindow uses exclusionMode and other props, avoiding raw layer props unless needed.
    // If we need it above windows:
    aboveWindows: true
    
    // State management
    property bool menuExpanded: false
    
    // Toggle button (always visible)
    ThemeToggleButton {
        id: toggleButton
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        
        onClicked: {
            root.menuExpanded = !root.menuExpanded;
            if (root.menuExpanded) {
                root.height = toggleButton.height + menuCard.height + 16;
            } else {
                root.height = toggleButton.height;
            }
        }
    }
    
    // Theme menu card (shown when expanded)
    ThemeMenuCard {
        id: menuCard
        visible: root.menuExpanded
        opacity: root.menuExpanded ? 1.0 : 0.0
        
        anchors {
            right: parent.right
            bottom: toggleButton.top
            bottomMargin: 16
        }
        
        scale: root.menuExpanded ? 1.0 : 0.8
        transformOrigin: Item.BottomRight
        
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }
}
