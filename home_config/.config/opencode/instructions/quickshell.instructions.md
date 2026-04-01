# QuickShell Development Instructions

## Overview

QuickShell is a QtQuick-based toolkit for building desktop shells (bars, widgets, lock screens, display managers). This guide covers QuickShell development for Hyprland ricing.

## QuickShell Documentation

- Main Docs: https://quickshell.org/docs/guide/introduction/
- Type Reference: https://quickshell.outfoxxed.me/docs/master/types/
- Examples: https://git.outfoxxed.me/outfoxxed/quickshell-examples

## Project Structure

For a full Hyprland rice, organize your project properly:

```
~/.config/quickshell/
├── my-rice/
│   ├── shell.qml              # Main entry point
│   ├── config.qml             # Configuration
│   ├── components/            # Reusable components
│   │   ├── Bar.qml
│   │   ├── Clock.qml
│   │   ├── Workspaces.qml
│   │   ├── SystemTray.qml
│   │   └── Battery.qml
│   ├── widgets/               # Individual widgets
│   │   ├── date.qml
│   │   ├── volume.qml
│   │   ├── brightness.qml
│   │   └── media.qml
│   ├── services/              # Service singletons
│   │   ├── Time.qml
│   │   ├── Audio.qml
│   │   └── Network.qml
│   ├── styles/                # Styling
│   │   ├── theme.qml
│   │   └── colors.qml
│   └── lib/                  # Helper functions
│       ├── utils.js
│       └── constants.qml
```

### Shell Entry Point Pattern

```qml
// shell.qml
import Quickshell

Scope {
    // Import components
    Bar {}
    
    // Services as singletons
    Time {}
    AudioService {}
}
```

## Core Types

### Quickshell Singleton

The main singleton providing system integration:

```qml
import Quickshell

// Key properties
Quickshell.screens        // List of all monitors
Quickshell.dataDir         // ~/.local/share/quickshell/by-shell/<id>
Quickshell.shellDir        // Path to config folder
Quickshell.cacheDir        // ~/.cache/quickshell/by-shell/<id>
Quickshell.clipboardText   // System clipboard
Quickshell.processId       // QuickShell PID

// Key functions
Quickshell.reload()                    // Reload config
Quickshell.iconPath("icon-name")       // Get theme icon path
Quickshell.dataPath("file")           // Data directory path
Quickshell.env("VAR_NAME")            // Get environment variable

// Signals
Quickshell.onReloadCompleted()        // Reload finished
Quickshell.onReloadFailed(error)      // Reload error
```

### PanelWindow

For bars, widgets, overlays:

```qml
import Quickshell

PanelWindow {
    // Anchors - attach to screen edges
    anchors {
        top: true
        bottom: false
        left: true
        right: true
    }
    
    // Properties
    implicitHeight: 30
    exclusionMode: ExclusionMode.Auto
    aboveWindows: true
    focusable: false
    
    // Margins from edges
    margins {
        top: 0
        bottom: 5
        left: 0
        right: 0
    }
    
    // Exclusive zone for window manager
    exclusiveZone: 30
    
    // Content
    Text {
        anchors.centerIn: parent
        text: "Hello World"
    }
}
```

### FloatingWindow

For standard desktop windows:

```qml
FloatingWindow {
    width: 400
    height: 300
    title: "My Window"
    
    Text {
        text: "Floating content"
    }
}
```

### Scope

Share state across components:

```qml
Scope {
    id: root
    property string timeString: ""
    property bool isDarkMode: true
    
    // Accessible from all child components
    ClockWidget {
        timeText: root.timeString
    }
    
    SettingsWidget {
        darkModeEnabled: root.isDarkMode
    }
}
```

### Variants

Create instances per monitor:

```qml
Variants {
    model: Quickshell.screens
    
    PanelWindow {
        required property var modelData  // Screen object
        
        screen: modelData
        anchors {
            top: true
            left: true
            right: true
        }
        
        // Auto-creates window for each monitor
    }
}
```

### Singleton Type

Global singletons accessible anywhere:

```qml
// Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property string time: ""
    
    SystemClock {
        precision: SystemClock.Seconds
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.time = new Date().toLocaleTimeString()
    }
}
```

Usage:

```qml
import QtQuick

Text {
    text: Time.time  // Access singleton directly
}
```

## Quickshell.Io - Process & IPC

### Process

Run external commands:

```qml
import Quickshell.Io

Process {
    id: dateProcess
    running: true
    command: ["date", "+%H:%M"]
    
    stdout: StdioCollector {
        onStreamFinished: clockText.text = this.text
    }
}

// Re-run on interval
Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: dateProcess.running = true
}
```

Advanced Process:

```qml
Process {
    command: ["python", "script.py"]
    workingDirectory: "/home/user"
    
    environment: {
        "PYTHONPATH": "/custom/path",
        "DEBUG": "1"
    }
    
    clearEnvironment: false
    
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    
    onStarted: console.log("Started")
    onExited: (code, status) => console.log("Exited:", code)
}
```

### Socket / SocketServer

For IPC communication:

```qml
// Server
SocketServer {
    id: server
    path: "/tmp/my-socket"
    
    onIncomingConnection: (socket) => {
        socket.onMessage: (msg) => {
            console.log("Received:", msg);
            socket.send("pong");
        }
    }
}

// Client
Socket {
    id: client
    path: "/tmp/my-socket"
    
    onConnected: client.send("ping")
    onMessage: (msg) => console.log("Response:", msg)
}
```

### IpcHandler

For Hyprland/i3 socket communication:

```qml
IpcHandler {
    id: hyprlandIpc
    
    // Subscribe to events
    onEvent: (event, payload) => {
        console.log("Hyprland event:", event, payload);
    }
    
    // Send commands
    Component.onCompleted: {
        hyprlandIpc.send("dispatch", "exec", "echo hello");
    }
}
```

### FileView

Watch files for changes:

```qml
FileView {
    path: "/path/to/config"
    
    onContentsChanged: console.log("Config changed")
}
```

## Quickshell.Hyprland - Hyprland Integration

### Hyprland Singleton

```qml
import Quickshell.Hyprland

Hyprland {
    id: hypr
    
    // Properties
    monitors:     // All monitors
    workspaces:   // All workspaces
    toplevels:    // All windows
    focusedMonitor
    focusedWorkspace
    activeToplevel
    
    // Functions
    function dispatch(request: string): void
    function refreshMonitors(): void
    function refreshWorkspaces(): void
    function refreshToplevels(): void
    
    // Signals
    onRawEvent: (event) => console.log(event)
}
```

### HyprlandMonitor

```qml
HyprlandMonitor {
    // Properties
    id: number
    name: string
    description: string
    width: number
    height: number
    x: number
    y: number
    scale: number
    refreshRate: number
    focusedWorkspace: HyprlandWorkspace
}
```

### HyprlandWorkspace

```qml
HyprlandWorkspace {
    // Properties
    id: number          // Negative for named workspaces
    name: string
    monitor: HyprlandMonitor
    windows: list       // Windows in this workspace
}
```

### HyprlandToplevel

```qml
HyprlandToplevel {
    // Properties
    title: string
    appId: string      // Hyprland window class
    initialTitle: string
    pid: number
    workspace: HyprlandWorkspace
    monitor: HyprlandMonitor
    isFloating: bool
    isFullscreen: bool
    isFocused: bool
    
    // Functions
    function focus(): void
    function close(): void
    function setFloating(floating: bool): void
    function setFullscreen(fullscreen: bool): void
}
```

### GlobalShortcut

Register global keybindings:

```qml
import Quickshell.Hyprland

GlobalShortcut {
    sequence: "SUPER + P"
    onTriggered: {
        console.log("Shortcut triggered!");
        Hyprland.dispatch("exec", "echo shortcut");
    }
}
```

### Complete Workspaces Example

```qml
import Quickshell
import Quickshell.Hyprland
import QtQuick

Scope {
    Variants {
        model: Hyprland.monitors
        
        PanelWindow {
            required property var modelData
            
            anchors {
                top: true
                left: true
                right: true
            }
            
            RowLayout {
                anchors.fill: parent
                
                // Workspace indicators
                Row {
                   Repeater {
                        model: Hyprland.workspaces.filter(
                            ws => ws.monitor.name === modelData.name
                        )
                        
                        delegate: Rectangle {
                            width: 30
                            height: 30
                            color: modelData.focusedWorkspace.id === model.id 
                                ? "green" : "gray"
                        }
                    }
                }
                
                // Current window title
                Text {
                    text: Hyprland.activeToplevel?.title || ""
                    elide: Text.ElideRight
                }
            }
        }
    }
}
```

## Quickshell.Services.Mpris - Media Controls

### Mpris Singleton

```qml
import Quickshell.Services.Mpris

Mpris {
    id: mpris
    
    players: list  // All MPRIS players
}
```

### MprisPlayer

```qml
MprisPlayer {
    // Properties
    playbackStatus: MprisPlaybackState  // Playing, Paused, Stopped
    loopStatus: MprisLoopState         // None, Track, Playlist
    volume: number                     // 0.0 - 1.0
    position: number                    // Position in ms
    metadata: object                   // Song info
    
    // Song metadata
    metadata.title: string
    metadata.artist: string
    metadata.album: string
    metadata.artUrl: string
    
    // Functions
    function play(): void
    function pause(): void
    function stop(): void
    function playPause(): void
    function next(): void
    function previous(): void
    function seek(position: number): void
}
```

### Media Widget Example

```qml
Scope {
    property var currentPlayer: Mpris.players[0]
    
    Row {
        visible: root.currentPlayer != null
        
        Text {
            text: root.currentPlayer?.metadata.title || "No media"
        }
        
        IconButton {
            icon: "media-previous"
            onClicked: root.currentPlayer?.previous()
        }
        
        IconButton {
            icon: root.currentPlayer?.playbackStatus === MprisPlaybackState.Playing 
                ? "media-pause" : "media-play"
            onClicked: root.currentPlayer?.playPause()
        }
        
        IconButton {
            icon: "media-next"
            onClicked: root.currentPlayer?.next()
        }
        
        Text {
            text: root.currentPlayer?.metadata.artist || ""
        }
    }
}
```

## Quickshell.Services.Notifications

### NotificationServer

Receive notifications:

```qml
import Quickshell.Services.Notifications

NotificationServer {
    id: notifications
    
    // Properties
    trackedNotifications: list
    
    // Configuration
    bodySupported: true
    actionsSupported: true
    
    // Signal
    onNotification: (notification) => {
        console.log("Notification:", notification.body);
        // Set tracked = true to keep it
        notification.tracked = true;
    }
}
```

### Notification

```qml
Notification {
    // Properties
    id: string
    appName: string
    title: string
    body: string
    urgency: NotificationUrgency
    tracked: bool
    
    // Functions
    function close(): void
}
```

## Quickshell.Services.SystemTray

### SystemTray

```qml
import Quickshell.Services.SystemTray

SystemTray {
    id: tray
    
    items: list  // All tray icons
}
```

### SystemTrayItem

```qml
SystemTrayItem {
    // Properties
    id: string
    icon: string
    tooltip: string
    menu: QmlObject
    
    // Functions
    function activate(): void
    function contextMenu(): void
}
```

## Quickshell.Services.UPower - Battery

### UPower

```qml
import Quickshell.Services.UPower

UPower {
    id: upower
    
    // Properties
    displayDevice: UPowerDevice   // Main battery
    onBattery: bool              // Is on battery
    devices: list                 // All devices
    
    // UPowerDevice properties
    // - percentage: number (0-100)
    // - timeToEmpty: number (seconds)
    // - timeToFull: number (seconds)
    // - state: UPowerDeviceState
    // - isPresent: bool
}
```

### Battery Widget Example

```qml
import Quickshell.Services.UPower

Scope {
    readonly property var battery: UPower.displayDevice
    
    Row {
        Icon {
            source: Quickshell.iconPath(
                root.battery.percentage > 20 
                    ? "battery-good" 
                    : "battery-low"
            )
        }
        
        Text {
            text: root.battery.percentage + "%"
            
            color: root.battery.percentage < 20 
                ? "red" 
                : "white"
        }
        
        visible: UPower.onBattery
    }
}
```

## Quickshell.Networking

### Networking

```qml
import Quickshell.Networking

Networking {
    id: net
    
    // Properties
    devices: list            // Network devices
    wifiEnabled: bool        // Toggle WiFi
    backend: NetworkBackendType
    
    // NetworkDevice properties
    // - type: DeviceType (Wifi, Ethernet, Bluetooth)
    // - state: NetworkDeviceState
    // - interface: string
    
    // WifiDevice additional properties
    // - ssid: string
    // - strength: number (0-100)
    // - secured: bool
    // - networks: list
}
```

### Network Widget Example

```qml
Scope {
    Row {
        Icon {
            source: Quickshell.iconPath(
                Networking.wifiEnabled ? "wifi" : "wifi-off"
            )
        }
        
        Text {
            text: {
                const dev = Networking.devices[0];
                if (dev?.type === DeviceType.Wifi) {
                    return dev.ssid + " (" + dev.strength + "%)";
                }
                return "Disconnected";
            }
        }
    }
}
```

## Quickshell.Wayland

### WlrLayershell

For Wayland layer shells:

```qml
import Quickshell.Wayland

PanelWindow {
    // WlrLayershell as attached object
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickhsell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    // Layer values:
    // - WlrLayer.Background
    // - WlrLayer.Bottom       (below normal windows)
    // - WlrLayer.Top         (above normal, below overlays)
    // - WlrLayer.Overlay    (topmost)
}
```

### IdleMonitor

Screen lock detection:

```qml
import Quickshell.Wayland

IdleMonitor {
    id: idle
    
    timeout: 300000  // 5 minutes in ms
    
    onIdleChanged: (idle) => {
        if (idle) {
            console.log("Screen locked");
        }
    }
}
```

## Common Patterns

### Multi-Monitor Bar

```qml
import Quickshell
import Quickshell.Hyprland
import QtQuick

Scope {
    property string time: ""
    property var activePlayer: Mpris.players[0]
    
    // Single time source
    SystemClock {
        id: clock
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
    }
    
    // Create bar per monitor
    Variants {
        model: Quickshell.screens
        
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                
                anchors {
                    top: true
                    left: true
                    right: true
                }
                
                implicitHeight: 32
                
                RowLayout {
                    anchors.fill: parent
                    
                    // Clock
                    Text {
                        text: clock.date.toLocaleTimeString()
                    }
                    
                    // Workspaces
                    Row {
                        Repeater {
                            model: Hyprland.workspaces
                            delegate: Text {
                                text: model.id
                            }
                        }
                    }
                    
                    // Media
                    Text {
                        text: root.activePlayer?.metadata.title || ""
                    }
                }
            }
        }
    }
}
```

### Global Keybindings

```qml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Scope {
    // Volume control
    GlobalShortcut {
        sequence: "SUPER + F12"
        onTriggered: {
            const player = Mpris.players[0];
            if (player) {
                player.volume = Math.min(1.0, player.volume + 0.1);
            }
        }
    }
    
    GlobalShortcut {
        sequence: "SUPER + F11"
        onTriggered: {
            const player = Mpris.players[0];
            if (player) {
                player.playPause();
            }
        }
    }
    
    // Screenshot
    GlobalShortcut {
        sequence: "SUPER + Print"
        onTriggered: {
            Hyprland.dispatch("exec", "grim -g \"$(slurp)\" - | wl-copy");
        }
    }
}
```

## Debugging Tips

1. Console logging:
```qml
console.log("Value:", someValue);
console.warn("Warning:", warningMessage);
console.error("Error:", errorMessage);
```

2. Hot reload: QuickShell reloads on file save (watchFiles enabled by default)

3. Check logs: Look at QuickShell stdout/stderr for errors

4. Use `qmllint` for static analysis

## Best Practices

1. Use singletons for shared state
2. Use Variants for multi-monitor setups
3. Minimize binding chains
4. Use required properties for model data
5. Separate concerns (components, services, widgets)
6. Use proper project structure
7. Comment complex bindings
8. Test on multiple monitors
