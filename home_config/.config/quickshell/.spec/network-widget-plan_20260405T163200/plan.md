---
title: "Network Node Graph Widget Plan"
created-date: "2026-04-05"
git-branch: "feature/network-graph-widget"
---

# User Prompt

[Initial Prompt]
I want a network widget using quickshell for Arch Linux/Hyprland. Node-based connection representative. Opens like a drawer from status bar. Setup in the center, nodes for each connection spring out based on connection level. Hover/`<C-n>`/`<C-p>` keyboard motion to expand/push neighbors. `<C-f>` for fuzzy finding. Active connection draws a line to the center, both light up. Expanding node to full screen to show details. Password input expands the PC node.

[Second Prompt]
I already am developing a Rust backend in ./Backend/ which talks to NetworkManager Dbus to get access points. I also have Services/BackendService.qml connecting to the UNIX socket. However, storing state for modules might need more work if I expand to bluetooth later. Also, for the animation, connection nodes initially will be transparent, only when bouncing to calculated positions will they be visible.

[Third Prompt]
These suggestions [Decentralized state management via NetworkService.qml listening to BackendService, Smart ListModel diffing, Opacity & Spring Animation Tweaks, IPC Flow for password input] look solid. Also, in the plans, tell the planner to create a structure section that directly tells what files will be created and in which directory as well. The current architecture/design section is also a bit too general, I need it to have more details. Passed in the first and previous prompts and tell the planner to update the plan.

## Q&A Context

**Q: For the node graph layout, how would you prefer the network nodes to be positioned around the central PC node?**
**A:** Radial / Polar Coordinates (Recommended).

**Q: You mentioned being open to design suggestions for the "View Details" interaction. Which option sounds best for displaying network details (IP, gateway, frequency, etc.)?**
**A:** "Use a part of side drawer design, make it when I select a connection node, the panel widget will zoom up to that connection, and a side drawer will slide either from the left or right displaying the connection details while still able to see the connections in the background."

# Project Structure

The following directories and files will be created or modified to implement the widget:

- `Services/BackendService.qml`: (Existing) Acts as the pure UNIX socket transport layer communicating with the Rust backend.
- `Services/NetworkService.qml`: (New) Domain-specific service that listens to `BackendService` via `Connections`, parses network-specific IPC messages, and maintains the network state.
- `Modules/NetworkWidget/NetworkWidget.qml`: Main entry point for the widget UI, handling the drawer animation, fuzzy finder overlay, and keyboard navigation.
- `Modules/NetworkWidget/Components/GraphLayout.qml`: The custom polar coordinate engine that calculates positions and manages the nodes.
- `Modules/NetworkWidget/Components/PCNode.qml`: The central node component, including states for default display and expanded password input.
- `Modules/NetworkWidget/Components/NetworkNode.qml`: The individual connection node, handling its own hover states, opacity transitions, and spring animations.
- `Modules/NetworkWidget/Components/ActiveEdge.qml`: The canvas/shape component drawing the glowing line between the `PCNode` and the active `NetworkNode`.
- `Modules/NetworkWidget/Components/NetworkDetailDrawer.qml`: The side panel that slides out to display IP, gateway, and MAC details when a node is zoomed.

# Architecture / Design

## Data Flow & State Management
- **Transport Layer**: `Services/BackendService.qml` remains a pure transport layer connecting to the UNIX socket of the Rust backend. It handles raw byte transmission and basic JSON parsing, emitting generic signals (e.g., `messageReceived(payload)`).
- **Domain Layer**: `Services/NetworkService.qml` uses a `Connections` object to listen to `BackendService`. This decentralized approach prevents `BackendService` from becoming a monolithic state store (future-proofing for Bluetooth). `NetworkService` handles network-specific IPC types (e.g., `TYPE_WIFI_LIST`, `TYPE_WIFI_STATUS`).
- **Smart ListModel Diffing**: Instead of clearing and repopulating the `ListModel` on every backend update (which destroys QML component instances and breaks animations), `NetworkService` will implement a smart diffing algorithm. It will match incoming access points by BSSID/SSID. New networks are appended, missing networks are removed, and existing networks have their properties (signal strength, active state) updated inline. This ensures `Behavior` animations remain fluid.
- **IPC Actions**: For connecting to a network, `NetworkService` exposes a method `connectToNetwork(ssid, password)` that serializes a JSON payload and calls `BackendService.sendRequest({...})`. Feedback loops (success/failure) are routed back through the same `Connections` listener.

## Physics & Graph Layout Logic
- **Coordinate System**: A polar coordinate system mapped to Cartesian ($x = r \cos(\theta)$, $y = r \sin(\theta)$) relative to the screen center ($width/2$, $height/2$).
- **Radius Calculation**: Distance $r$ is inversely proportional to signal strength (e.g., $r = MAX\_RADIUS - (signal\_percentage * SCALING\_FACTOR)$).
- **Angle Calculation**: Nodes are initially distributed evenly across $360^\circ$ ($\theta = index * (360 / count)$).
- **Repulsion / Push Effect**: When a node is hovered or focused via keyboard, it expands (scale increases). To prevent overlap, adjacent nodes calculate their angular distance to the focused node and apply a small angular offset ($\Delta\theta$) away from it.
- **Animations**:
  - Positional updates (from $x,y$ to $x_{new},y_{new}$) use `Behavior on x { SpringAnimation { spring: 2.0; damping: 0.15; mass: 1.0 } }`.
  - On open, nodes start at $r=0$ (center), with `opacity: 0.0`. Their target properties are set to their calculated radial positions and `opacity: 1.0`. `Behavior on opacity` creates the fade-in effect during the bounce. On close, the target reverts to $r=0, opacity: 0.0$.

## Keyboard Navigation & Interactions
- **Vim Motions**: A `FocusScope` captures `<C-n>` (next) and `<C-p>` (previous) using `Keys.onPressed`. The `NetworkService` `ListModel` is sorted by signal strength. Changing the `currentIndex` triggers the same "push effect" as a mouse hover.
- **Fuzzy Finding**: `<C-f>` opens a `TextField` (`NetworkWidget.qml`). Text input filters a visual proxy model (or toggles visibility/opacity of non-matching nodes in the `ListModel`), automatically focusing the top match.

# Implementation Steps

1. **Backend Integration (NetworkService)**
   - Create `NetworkService.qml`.
   - Add `Connections { target: BackendService; onMessageReceived: ... }`.
   - Implement the smart `ListModel` diffing logic (update/insert/remove based on SSID/BSSID).
   - Implement `sendRequest` wrappers for connect/disconnect commands.
2. **Widget Scaffold & Drawer Animation**
   - Create `NetworkWidget.qml` in `Modules/NetworkWidget/`.
   - Setup QuickShell window/panel docked to the status bar with open/close state transitions modifying height or Y-offset.
3. **Graph Layout & Node Components**
   - Create `GraphLayout.qml` to bind to the `NetworkService` model and calculate $r$ and $\theta$.
   - Create `PCNode.qml` fixed at the center.
   - Create `NetworkNode.qml`. Implement `SpringAnimation` on `x`, `y` and a `NumberAnimation` on `opacity`.
   - Bind node visibility and coordinate targets to the widget's `opened` state.
4. **Interaction Layer**
   - In `GraphLayout.qml`, add logic to modify $\theta$ of neighbors when a specific node's `isFocused` or `isHovered` property is true.
   - Implement `<C-n>`, `<C-p>`, and `<C-f>` handlers using `FocusScope` and `Keys`.
5. **Connection State & Edge Drawing**
   - Create `ActiveEdge.qml` using `QtQuick.Shapes` `PathLine` connecting `PCNode` coordinates to the active `NetworkNode` coordinates. Apply a glow effect using `QtGraphicalEffects` or custom shaders.
   - Implement the password flow: On select, animate `PCNode.qml` width/height to reveal a `TextField`. On `<Enter>`, call `NetworkService.connectToNetwork()`.
6. **Detail View Drawer**
   - Create `NetworkDetailDrawer.qml`.
   - Implement the zoom state: Apply a `Scale` and `Translate` transform to `GraphLayout.qml` to center the selected node.
   - Animate `NetworkDetailDrawer.qml` sliding in from the screen edge, populating it with data from the active `ListModel` item.

# Testing Strategy

- **Backend Mocking**: During initial UI development, inject a mock payload into `NetworkService` to simulate Rust backend DBus data without needing actual DBus signals.
- **Diffing Verification**: Send payloads with slight signal changes to ensure `ListModel` updates properties without destroying the QML nodes (verify animations don't reset).
- **Physics Tuning**: Interactively test `spring`, `damping`, and `mass` values for both the open/close sequence and the hover push-effect to ensure stability (prevent infinite oscillation).
- **Input Flow**: Test the password input focus handoff (from global window to `PCNode` TextField) and ensure `sendRequest` generates the correct JSON structure for the Rust backend.