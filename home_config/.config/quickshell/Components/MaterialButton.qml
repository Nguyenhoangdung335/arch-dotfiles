import QtQuick
import QtQuick.Effects

// Material Design button with ripple effect
Rectangle {
    id: root
    
    // Public API
    property string text: ""
    property string iconSource: ""
    property bool filled: true
    property bool elevated: false
    property color buttonColor: "#6750A4"
    property color textColor: "#FFFFFF"
    signal clicked()
    
    // Dimensions
    implicitWidth: contentRow.implicitWidth + 48
    implicitHeight: 40
    radius: 20
    
    // Styling
    color: filled ? buttonColor : "transparent"
    border.width: filled ? 0 : 1
    border.color: buttonColor
    
    // Elevation shadow
    Rectangle {
        visible: elevated && filled
        anchors.fill: parent
        anchors.margins: -8
        z: -1
        radius: parent.radius
        color: "#000000"
        opacity: 0.2
    }
    
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8
        
        Image {
            visible: iconSource !== ""
            source: iconSource
            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: root.text
            color: filled ? textColor : buttonColor
            font.pixelSize: 14
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    // Ripple effect container
    Item {
        id: rippleContainer
        anchors.fill: parent
        clip: true
        
        Rectangle {
            id: ripple
            width: 0
            height: width
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.3)
            opacity: 0
            
            PropertyAnimation {
                id: rippleAnim
                target: ripple
                properties: "width,opacity"
                to: root.width * 2.5
                duration: 600
                easing.type: Easing.OutQuad
            }
            
            SequentialAnimation {
                id: fadeOut
                PauseAnimation { duration: 200 }
                NumberAnimation {
                    target: ripple
                    property: "opacity"
                    to: 0
                    duration: 400
                }
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onPressed: function(mouse) {
            ripple.x = mouse.x - ripple.width / 2;
            ripple.y = mouse.y - ripple.height / 2;
            ripple.opacity = 1;
            rippleAnim.restart();
            fadeOut.restart();
        }
        
        onClicked: root.clicked()
        
        onEntered: {
            root.opacity = 0.9;
        }
        
        onExited: {
            root.opacity = 1.0;
        }
    }
    
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 100 } }
}
