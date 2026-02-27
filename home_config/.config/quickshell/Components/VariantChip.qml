import QtQuick

Rectangle {
    id: root
    
    // --- Public API ---
    property string label: ""
    property bool isActive: false
    signal clicked()

    // --- Dimensions ---
    implicitWidth: contentText.width + 24
    implicitHeight: 36
    radius: 18 // Pill shape
    
    // --- Visuals ---
    // We assume a global theme is available, but since this is a generic component,
    // we don't hardcode imports. The parent Module will bind these properties.
    color: root.isActive ? "#000000" : "transparent" 
    border.width: root.isActive ? 0 : 1
    border.color: "#FFFFFF" 
    opacity: root.isActive ? 1.0 : 0.6

    // --- Text ---
    Text {
        id: contentText
        text: root.label
        color: root.isActive ? "#FFFFFF" : "#FFFFFF"
        anchors.centerIn: parent
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }

    // --- Interaction ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onEntered: {
            if (!root.isActive) {
                root.opacity = 0.9;
                root.color = root.border.color; // Fill with border color on hover
            }
        }
        
        onExited: {
            if (!root.isActive) {
                root.opacity = 0.6;
                root.color = "transparent";
            }
        }
        
        onClicked: root.clicked()
    }
    
    // --- Animations ---
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 200 } }
}
