import Quickshell
import QtQuick

// import "modules/bar"
// import "modules/notifications"
import "Modules/Sidebar"
import "Services" as Svc

ShellRoot {

    // Load Services on startup
    Component.onCompleted: {
        Svc.ThemeModel.load();
    }
    //
    // This creates a bar on every connected monitor automatically
    // Variants {
    //     model: Quickshell.screens
    //     // Bar {
    //     //     // Pass the specific screen to the Bar module
    //     //     screen: modelData
    //     // }
    // }

    // NotificationCenter {}
    // Single instance modules (like notifications)

    // Settings sidebar with theme and wallpaper switching
    // Toggle with GlobalShortcut (bind in Hyprland config or use IPC: qs ipc call sidebar toggle)
    Sidebar {}
}
