pragma Singleton
import QtQuick

QtObject {
    id: root

    // Global IPC Shortcuts (quickshell dbus names)
    property string toggleNetworkWidget: "toggleNetworkWidget"
    property string toggleSidebar: "toggleSidebar"
    property string toggleBackendTester: "toggleBackendTester"
    
    // Generic UI Local Keybinds
    property string closeWidget: "Escape"
    
    // Sidebar Local Keybinds (Qt.Sequence)
    property string sidebarNextTab: "Ctrl+Tab"
    property string sidebarNextTabAlt: "Right"
    property string sidebarNextTabVim: "l"
    
    property string sidebarPrevTab: "Ctrl+Shift+Tab"
    property string sidebarPrevTabAlt: "Left"
    property string sidebarPrevTabVim: "h"
    
    property string sidebarClose: "Escape"
    property string sidebarCloseAlt: "q"
}
