import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../Themes" as Th

Rectangle {
    id: chip
    
    property string family
    property string variant
    property var themeData 
    property bool isActive: false
    property bool contentReady: true // Bound by parent if needed for initial animations

    signal activate()

    width: 240
    height: 50
    radius: 8
    
    color: isActive ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.1) : "transparent"
    border.width: isActive ? 2 : 1
    border.color: isActive ? Th.Theme.primary : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)

    // ✨ IMPROVED: Smooth border transitions
    Behavior on border.color {
        ColorAnimation { duration: 250 }
    }
    Behavior on border.width {
        NumberAnimation { duration: 200 }
    }
    Behavior on color {
        ColorAnimation { duration: 250 }
    }
    
    // ✨ IMPROVED: Hover and active scale
    scale: clickArea.pressed ? 0.95 : (clickArea.containsMouse || isActive ? 1.02 : 1.0)
    Behavior on scale {
        SpringAnimation {
            spring: 3.5
            damping: 0.4
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 0
        
        // Left Section: Info & Activation
        MouseArea {
            id: clickArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: chip.activate()
            
            RowLayout {
                anchors.fill: parent
                spacing: 8
                
                // ✨ IMPROVED: Active indicator with animation
                Item {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 24

                    Rectangle {
                        anchors.centerIn: parent
                        width: 4
                        height: chip.isActive ? 24 : 0
                        radius: 2
                        color: Th.Theme.primary
                        
                        Behavior on height {
                            SpringAnimation {
                                spring: 3
                                damping: 0.5
                            }
                        }
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    // Variant Name
                    Text {
                        text: chip.variant.replace("_", " ")
                        color: Th.Theme.fg
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        
                        // ✨ Smooth color transition
                        Behavior on color {
                            ColorAnimation { duration: 250 }
                        }
                    }
                    
                    // ✨ IMPROVED: Color Preview with pop-in animation
                    Row {
                        spacing: 4
                        Repeater {
                            model: chip.themeData.previewColors
                            delegate: Rectangle {
                                required property color modelData
                                required property int index
                                
                                width: 12
                                height: 12
                                radius: 6
                                color: modelData
                                border.width: 1
                                border.color: Qt.rgba(0,0,0,0.1)
                                
                                // REVERTED: Staggered pop-in
                                scale: chip.contentReady ? 1 : 0
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.5
                                    }
                                }
                                
                                // ✨ Hover grow effect
                                property bool hovered: colorHover.containsMouse
                                
                                MouseArea {
                                    id: colorHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                                
                                transform: Scale {
                                    origin.x: width / 2
                                    origin.y: height / 2
                                    xScale: parent.hovered ? 1.3 : 1.0
                                    yScale: parent.hovered ? 1.3 : 1.0
                                    
                                    Behavior on xScale {
                                        SpringAnimation {
                                            spring: 4
                                            damping: 0.3
                                        }
                                    }
                                    Behavior on yScale {
                                        SpringAnimation {
                                            spring: 4
                                            damping: 0.3
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.margins: 4
            color: chip.border.color
            
            Behavior on color {
                ColorAnimation { duration: 250 }
            }
        }
        
        // ✨ IMPROVED: Details Button with hover animation
        Rectangle {
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            color: detailsArea.containsMouse
                   ? Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
                   : "transparent"
            
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
            
            // ✨ Scale on hover
            scale: detailsArea.pressed ? 0.9 : (detailsArea.containsMouse ? 1.1 : 1.0)
            Behavior on scale {
                SpringAnimation {
                    spring: 4
                    damping: 0.3
                }
            }
            
            Text {
                text: "⋮" 
                color: Th.Theme.secondary
                font.pixelSize: 18
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: detailsArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: detailsPopup.open()
            }
        }
    }
    
    // --- Enhanced Details Popup ---
    Popup {
        id: detailsPopup
        implicitWidth: 320
        implicitHeight: 400
        padding: 0
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: Overlay.overlay
        
        // ✨ IMPROVED: Smooth entrance animation
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.85
                    to: 1.0
                    duration: 300
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.3
                }
            }
        }
        
        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 1.0
                    to: 0.9
                    duration: 200
                    easing.type: Easing.InCubic
                }
            }
        }
        
        background: Rectangle {
            color: Th.Theme.bg
            border.color: Th.Theme.primary
            border.width: 2
            radius: 12
            
            // ✨ Enhanced shadow
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.margins: -6
                color: Qt.rgba(0,0,0,0.3)
                radius: 16
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // Popup Header
            Text {
                text: chip.family + " " + chip.variant
                font.pixelSize: 18
                font.bold: true
                color: Th.Theme.fg
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle { 
                Layout.fillWidth: true
                height: 1
                color: Th.Theme.surface
            }
            
            // Colors List with staggered entrance
            ListView {
                id: colorListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: chip.themeData.colors
                spacing: 8
                
                // ✨ Smooth scrolling
                flickDeceleration: 1500
                
                delegate: RowLayout {
                    width: ListView.view.width
                    spacing: 10
                    
                    required property var modelData
                    required property int index
                    
                    // ✨ Staggered entrance
                    opacity: detailsPopup.opened ? 1 : 0
                    transform: Translate {
                        x: detailsPopup.opened ? 0 : -20
                    }
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on x {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    // ✨ IMPROVED: Color Circle with hover scale
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: modelData.value
                        border.width: 1
                        border.color: Qt.rgba(1,1,1,0.1)
                        
                        scale: colorCircleHover.containsMouse ? 1.2 : 1.0
                        Behavior on scale {
                            SpringAnimation {
                                spring: 4
                                damping: 0.3
                            }
                        }
                        
                        MouseArea {
                            id: colorCircleHover
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                    
                    // Name
                    Text {
                        text: modelData.name
                        color: Th.Theme.fg
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }
                    
                    // Hex Input Group
                    HexCopyField {
                        colorValue: modelData.value
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    opacity: colorListView.moving ? 1.0 : 0.5
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
            }
        }
    }
}
