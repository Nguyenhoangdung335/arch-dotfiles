---
name: qt-qml-development
description: >
  Quick reference for Qt/QML and QuickShell development including project structure,
  common patterns, and debugging. Use this skill whenever working with QuickShell
  (bars, widgets, lock screens, display managers for Hyprland), writing QML components,
  building Qt 6 applications with QML, or anything involving QtQuick, PanelWindow,
  Variants, singletons, Hyprland integration, MPRIS media controls, system tray,
  battery/network widgets, or global shortcuts. Also use when the user mentions
  qmllint, LazyLoader, ComponentBehavior, required properties, or QML performance
  optimization.
---

# Qt/QML/QuickShell Development Quick Reference

## Quick Reference by Category

### Core QuickShell Types

| Type | Purpose |
|------|---------|
| `Quickshell` | Main singleton - screens, paths, clipboard |
| `PanelWindow` | Bar/widget windows with anchors |
| `FloatingWindow` | Standard desktop windows |
| `Scope` | Share state across components |
| `Variants` | Create instances per monitor |
| `Singleton` | Global singletons with pragma Singleton |

### Quickshell.Io

| Type | Purpose |
|------|---------|
| `Process` | Run external commands |
| `StdioCollector` | Read process stdout/stderr |
| `Socket` | Client socket for IPC |
| `SocketServer` | Server socket for IPC |
| `IpcHandler` | Hyprland/i3 IPC |
| `FileView` | Watch files for changes |

### Quickshell.Hyprland

| Type | Purpose |
|------|---------|
| `Hyprland` | Main singleton - monitors, workspaces, toplevels |
| `HyprlandMonitor` | Monitor info |
| `HyprlandWorkspace` | Workspace info |
| `HyprlandToplevel` | Window info |
| `GlobalShortcut` | Register keybindings |

### Quickshell.Services

| Module | Types |
|--------|-------|
| Mpris | `Mpris`, `MprisPlayer` |
| Notifications | `NotificationServer`, `Notification` |
| SystemTray | `SystemTray`, `SystemTrayItem` |
| UPower | `UPower`, `UPowerDevice` |
| Networking | `Networking`, `NetworkDevice`, `WifiDevice` |

### Quickshell.Wayland

| Type | Purpose |
|------|---------|
| `WlrLayershell` | Layer shell protocol |
| `IdleMonitor` | Screen lock detection |
| `ToplevelManager` | Wayland toplevels |
| `ScreencopyView` | Screenshot |

## Essential Patterns

### Multi-Monitor Bar

```qml
import Quickshell
import QtQuick

Variants {
    model: Quickshell.screens
    
    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true, left: true, right: true }
        implicitHeight: 32
    }
}
```

### Global Shortcut

```qml
import Quickshell.Hyprland

GlobalShortcut {
    sequence: "SUPER + P"
    onTriggered: console.log("Pressed!")
}
```

### Process with Interval

```qml
import Quickshell.Io

Process {
    id: proc
    running: true
    command: ["date", "+%H:%M"]
    stdout: StdioCollector {
        onStreamFinished: timeText.text = this.text
    }
}

Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: proc.running = true
}
```

### Media Player

```qml
import Quickshell.Services.Mpris

Text {
    text: Mpris.players[0]?.metadata.title || "No media"
}

IconButton {
    icon: "media-playback-pause"
    onClicked: Mpris.players[0]?.playPause()
}
```

### Singleton Pattern

```qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property string value: ""
}
```

Usage: `import MySingleton` then access as `MySingleton.value`

### Shell Entry Point

```qml
// shell.qml
import Quickshell

Scope {
    Bar {}
    TimeService {}
    AudioService {}
}
```

## QML Best Practices (Summary)

These are the most impactful practices. See `references/qml-best-practices.md` for full details.

### 1. Use Concrete Types

```qml
// Bad
property var size: 10

// Good
property int size: 10
```

### 2. Annotate Function Parameters

```qml
// Bad
function calculateArea(width, height) { ... }

// Good
function calculateArea(width: double, height: double): double { ... }
```

### 3. Use ComponentBehavior: Bound

```qml
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root
    ListView {
        delegate: Rectangle {
            height: root.delegateHeight  // Safe with Bound
        }
    }
}
```

### 4. Use Required Properties for Model Data

```qml
delegate: ItemDelegate {
    required property string title
    text: title
}
```

### 5. Avoid Deep Binding Chains

```qml
// Bad - re-evaluates on every change
Text { text: model.data.name + " - " + model.data.value }

// Good - use intermediate property
property string displayText: model.data.name + " - " + model.data.value
Text { text: displayText }
```

### 6. Use LazyLoader for Heavy Components

```qml
LazyLoader {
    source: "HeavyComponent.qml"
}
```

## Project Structure

```
~/.config/quickshell/<rice-name>/
├── shell.qml           # Entry point
├── components/         # Reusable UI
├── services/           # Singletons
├── widgets/           # Individual widgets
├── styles/            # Theming
└── lib/               # Helpers
```

## Debugging Checklist

- [ ] Check console.log() output
- [ ] Verify hot reload (save file)
- [ ] Check QML syntax with qmllint
- [ ] Verify imports are correct
- [ ] Check property types match
- [ ] Look for binding loops
- [ ] Verify required properties are set

## Performance Tips

1. Use concrete types instead of `var`
2. Avoid deep binding chains
3. Use LazyLoader for heavy components
4. Cache expensive calculations
5. Use required properties for model data

## Reference Files

For detailed patterns, complete type references, and comprehensive examples:

- **QuickShell full reference**: `references/quickshell-reference.md` - Complete QuickShell types, services, patterns, and examples
- **QML best practices**: `references/qml-best-practices.md` - Qt 6 QML optimization, debugging tools, common patterns

## Quick Links

- Docs: https://quickshell.org/docs/guide/introduction/
- Type Ref: https://quickshell.outfoxxed.me/docs/master/types/
- Examples: https://git.outfoxxed.me/outfoxxed/quickshell-examples
