import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../Themes" as Th

Rectangle {
    id: fieldRoot
    property color colorValue
    
    Layout.preferredWidth: 110
    Layout.preferredHeight: 30
    
    color: Th.Theme.surface
    radius: 6
    border.width: 1
    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
    
    // ✨ Hover effect
    scale: fieldHover.containsMouse ? 1.03 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    
    property alias containsMouse: fieldHover.containsMouse
    
    MouseArea {
        id: fieldHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Hex Text
        TextField {
            id: hexInput
            text: fieldRoot.colorValue.toString()
            readOnly: true
            color: Th.Theme.fg
            
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            background: Item {}
            font.pixelSize: 12
            font.family: "Monospace"
            leftPadding: 8
            verticalAlignment: Text.AlignVCenter
            selectByMouse: true
        }
        
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: fieldRoot.border.color
        }
        
        // ✨ IMPROVED: Animated Copy Button
        Button {
            id: copyBtn
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            flat: true
            
            contentItem: Text {
                text: copyBtn.copied ? "✓" : "❐"
                color: copyBtn.copied ? Th.Theme.success : Th.Theme.secondary
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                
                // ✨ Smooth color transition
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                
                // ✨ Pop animation on copy
                scale: copyBtn.copied ? 1.2 : 1.0
                Behavior on scale {
                    SequentialAnimation {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                        PauseAnimation { duration: 1000 }
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
            
            property bool copied: false
            
            background: Rectangle {
                color: copyBtn.hovered ? Qt.rgba(1,1,1,0.1) : "transparent"
                radius: 4
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            onClicked: {
                hexInput.selectAll()
                hexInput.copy()
                hexInput.deselect()
                
                copied = true
                timer.restart()
            }
            
            Timer {
                id: timer
                interval: 1500
                onTriggered: copyBtn.copied = false
            }
        }
    }
}
