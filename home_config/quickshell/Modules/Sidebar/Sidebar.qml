import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../../Themes" as Th

// Right-side sliding sidebar with improved animations
PanelWindow {
    id: root
    
    property bool isOpen: false
    property int activeTab: 0
    
    readonly property int sidebarWidth: 400
    readonly property int collapsedWidth: 0
    
    color: "transparent"
    
    anchors {
        top: true
        right: true
        bottom: true
    }
    
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    
    implicitWidth: root.isOpen ? root.sidebarWidth : 0

    Behavior on implicitWidth {
        NumberAnimation {
            id: windowAnim
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: contentWrapper
        property bool animationRunning: slideAnim.running
        
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        // anchors.right: parent.right
        
        // width: root.isOpen ? root.sidebarWidth : root.collapsedWidth
        width: root.sidebarWidth
        x: root.isOpen ? parent.width - width : parent.width
        clip: false
        enabled: root.isOpen || windowAnim.running

        // transformOrigin: Item.Right
        // scale: root.isOpen ? 1 : 0
        // opacity: root.isOpen ? 1 : 0
        
        Behavior on x {
            NumberAnimation {
                id: slideAnim
                duration: 500
                easing.type: Easing.InQuad
                // easing.overshoot: 0.8
            }
        }
        
        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutQuad
            }
        }

        // Glassmorphism Background
        Rectangle {
            id: blurBackground
            anchors.fill: parent
            // visible: root.isOpen
            opacity: contentWrapper.x < root.sidebarWidth * 0.3 ? 1 : 0
            // opacity: root.isOpen ? 1 : 0
            enabled: root.isOpen || slideAnim.running

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
            
            color: Qt.rgba(
                Th.Theme.bg.r,
                Th.Theme.bg.g,
                Th.Theme.bg.b,
                0.85
            )
            
            border.width: 1
            border.color: Qt.rgba(
                Th.Theme.fg.r,
                Th.Theme.fg.g,
                Th.Theme.fg.b,
                0.15
            )
            
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: root.isOpen ? 0.5 : 0.0
                saturation: 1.2

                Behavior on blur {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
        
        // Content Layer
        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            visible: contentWrapper.width > 0
            
            // ✨ Fade in/out based on sidebar state
            // opacity: root.isOpen ? 1 : 0
            opacity: root.isOpen && contentWrapper.x < root.sidebarWidth * 0.3 ? 1 : 0
            
            // Behavior on opacity {
            //     NumberAnimation { 
            //         duration: 250
            //         easing.type: Easing.OutCubic
            //     }
            // }
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Text {
                    text: "Settings"
                    color: Th.Theme.fg
                    font.pixelSize: 24
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                // Close button with hover effect
                // Rectangle {
                //     width: 32
                //     height: 32
                //     radius: 16
                //     
                //     color: closeArea.containsMouse 
                //            ? Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)
                //            : "transparent"
                //     
                //     Behavior on color { 
                //         ColorAnimation { duration: 200 } 
                //     }
                //     
                //     // ✨ Scale on hover
                //     scale: closeArea.pressed ? 0.9 : (closeArea.containsMouse ? 1.1 : 1.0)
                //     
                //     Behavior on scale {
                //         NumberAnimation {
                //             duration: 150
                //             easing.type: Easing.OutCubic
                //         }
                //     }
                //     
                //     Text {
                //         anchors.centerIn: parent
                //         text: "✕"
                //         color: Th.Theme.fg
                //         font.pixelSize: 16
                //     }
                //     
                //     MouseArea {
                //         id: closeArea
                //         anchors.fill: parent
                //         hoverEnabled: true
                //         cursorShape: Qt.PointingHandCursor
                //         onClicked: root.isOpen = false
                //     }
                // }
            }
            
            // Tab Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                TabButton {
                    text: "🎨 Themes"
                    isActive: root.activeTab === 0
                    onClicked: root.activeTab = 0
                    Layout.fillWidth: true
                }
                
                TabButton {
                    text: "🖼️ Wallpapers"
                    isActive: root.activeTab === 1
                    onClicked: root.activeTab = 1
                    Layout.fillWidth: true
                }
            }
            
            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
            }
            
            // Tab Content with simple fade
            // Loader {
            //     id: tabLoader
            //     Layout.fillWidth: true
            //     Layout.fillHeight: true
            //     
            //     sourceComponent: root.activeTab === 0 ? themeTab : wallpaperTab
            //     
            //     // ✨ Fade transition on tab change
            //     opacity: 1
            //     
            //     Behavior on opacity {
            //         NumberAnimation { 
            //             duration: 200
            //             easing.type: Easing.InOutQuad
            //         }
            //     }
            //     
            //     onSourceComponentChanged: {
            //         opacity = 0
            //         Qt.callLater(function() {
            //             opacity = 1
            //         })
            //     }
            // }
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.activeTab

                ThemeTab {}
                WallpaperTab {}
            }
        }
    }
    
    // Tab Components
    Component {
        id: themeTab
        ThemeTab {}
    }
    
    Component {
        id: wallpaperTab
        WallpaperTab {}
    }
    
    // Toggle Function
    function toggle() {
        isOpen = !isOpen;
    }
    
    // GlobalShortcut
    GlobalShortcut {
        id: quickshell
        name: "sidebarToggle"
        description: "Toggle settings sidebar"
        
        onPressed: root.toggle()
    }
    
    // IPC Handler
    IpcHandler {
        target: "sidebar"
        
        function toggle(): void {
            root.toggle();
        }
        
        function open(): void {
            root.isOpen = true;
        }
        
        function close(): void {
            root.isOpen = false;
        }
    }
    
    // Enhanced TabButton Component
    component TabButton: Rectangle {
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
}
