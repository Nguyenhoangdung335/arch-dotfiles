import QtQuick

import "../Themes" as Th

Rectangle {
    id: tabBtn
    
    property string text: ""
    property bool isActive: false
    signal clicked()
    
    height: 40
    radius: 8
    
    color: isActive 
           ? Th.Theme.primary
           : tabBtnArea.containsMouse 
             ? Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
             : "transparent"
    
    border.width: isActive ? 0 : 1
    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)
    
    // ✨ Smooth color transitions
    Behavior on color { 
        ColorAnimation { 
            duration: 200
            easing.type: Easing.InOutQuad
        } 
    }
    
    // ✨ Press feedback
    scale: tabBtnArea.pressed ? 0.95 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: tabBtn.text
        color: tabBtn.isActive ? Th.Theme.bg : Th.Theme.fg
        font.pixelSize: 14
        font.weight: Font.Medium
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
    
    MouseArea {
        id: tabBtnArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tabBtn.clicked()
    }
    
    // ✨ Active indicator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: tabBtn.isActive ? parent.width - 16 : 0
        height: 2
        radius: 1
        color: Th.Theme.bg
        visible: tabBtn.isActive
        
        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }
}
