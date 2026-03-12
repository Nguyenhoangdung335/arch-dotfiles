pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../../Themes" as Th
import "../../Components" as Comp
import "../../Config" as Cfg

// Right-side sliding sidebar with improved animations
PanelWindow {
    id: root
    
    property bool isOpen: false
    property int activeTab: 0
    property bool isAnimating: slideAnim.running
    
    readonly property int sidebarWidth: Screen.width > 0 ? Math.min(Math.max(Screen.width * 0.22, 350), 500) : 400
    
    color: "transparent"
    
    anchors {
        top: true
        right: true
        bottom: true
    }
    
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    
    // 1. Fix focus loss by only making it focusable when open
    focusable: root.isOpen
    
    // ✨ FIX "mid-air expanding": Keep window geometry constant to avoid Hyprland layer animations.
    // Instead, rely on contentWrapper's X translation and clip input via mask.
    implicitWidth: root.sidebarWidth
    
    mask: Region {
        item: contentWrapper
    }

    // Keyboard navigation
    Item {
        anchors.fill: parent
        focus: root.isOpen
        
        Shortcut {
            sequences: [Cfg.KeyBinds.sidebarNextTab, Cfg.KeyBinds.sidebarNextTabAlt, Cfg.KeyBinds.sidebarNextTabVim]
            onActivated: root.activeTab = (root.activeTab + 1) % 2
            enabled: root.isOpen
        }
        
        Shortcut {
            sequences: [Cfg.KeyBinds.sidebarPrevTab, Cfg.KeyBinds.sidebarPrevTabAlt, Cfg.KeyBinds.sidebarPrevTabVim]
            onActivated: root.activeTab = (root.activeTab - 1 + 2) % 2
            enabled: root.isOpen
        }
        
        Shortcut {
            sequences: [Cfg.KeyBinds.sidebarClose, Cfg.KeyBinds.sidebarCloseAlt]
            onActivated: root.close()
            enabled: root.isOpen
        }
    }

    Item {
        id: contentWrapper
        property bool animationRunning: slideAnim.running
        
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        
        width: root.sidebarWidth
        
        // 2. Fix animation: slide from right side
        x: root.isOpen ? 0 : root.sidebarWidth
        clip: false
        enabled: root.isOpen || root.isAnimating
        
        Behavior on x {
            NumberAnimation {
                id: slideAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        // REVERTED: Glassmorphism Background with MultiEffect
        Rectangle {
            id: blurBackground
            anchors.fill: parent
            
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
            // 4. Fixed margin/padding
            anchors.margins: 20
            spacing: 16
            visible: contentWrapper.width > 0
            
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
            }
            
            // Tab Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Comp.SidebarTabButton {
                    text: "🎨 Themes"
                    isActive: root.activeTab === 0
                    onClicked: root.activeTab = 0
                    Layout.fillWidth: true
                }
                
                Comp.SidebarTabButton {
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
            
            // Tab Content
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.activeTab

                ThemeTab {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                WallpaperTab {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
    
    // Toggle Function
    function toggle() {
        isOpen = !isOpen;
    }
    
    function open() {
        isOpen = true;
    }
    
    function close() {
        isOpen = false;
    }
    
    // GlobalShortcut
    GlobalShortcut {
        id: quickshell
        name: Cfg.KeyBinds.toggleSidebar
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
}
