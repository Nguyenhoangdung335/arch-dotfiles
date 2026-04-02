pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "../../Themes" as Th
import "../../Components" as Comp
import "../../Config" as Cfg
import "../../Services" as Svc

// Toggleable, resizable backend IPC debugger window
Window {
    id: root

    property bool isOpen: false
    property int activeTab: 0
    property string selectedModule: "network"
    property string lastSendPayload: ""
    property bool moduleMenuOpen: false

    // ── Window Configuration ──────────────────────────────────────────
    visible: root.isOpen
    width: 520
    height: 700
    minimumWidth: 350
    minimumHeight: 400
    color: "transparent"

    // Center on screen on first show
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    title: "Backend Tester"

    // ── Available modules (extend when adding bluetooth, audio, etc.) ─
    ListModel {
        id: moduleModel
        ListElement { name: "network"; label: "Network" }
        // ListElement { name: "bluetooth"; label: "Bluetooth" }
    }

    // ── Known actions per module (for autocomplete / quick buttons) ──
    readonly property var knownActions: ({
        "network": [
            { name: "toggle_wifi", label: "Toggle WiFi", argsHint: "" },
            { name: "scan_wifi", label: "Scan WiFi", argsHint: "" },
            { name: "connect", label: "Connect", argsHint: '{"ssid": "MyNetwork"}' },
            { name: "get_wifi_device_object_path", label: "WiFi Device Path", argsHint: "" },
            { name: "get_current_state", label: "Get Current Latest State", argsHint: "" },
            { name: "get_hostname", label: "Get Hostname", argsHint: "" },
            { name: "get_saved_connections", label: "Get SavedConnections", argsHint: "" }
        ]
        // "bluetooth": [ ... ]
    })

    // ── Message log models ─────────────────────────────────────────────
    ListModel {
        id: sentLog
    }
    
    ListModel {
        id: recvLog
    }

    property bool autoScroll: true

    // ── Keyboard shortcuts ────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: root.close()
        enabled: root.isOpen
    }

    // ── GlobalShortcut (Hyprland integration) ─────────────────────────
    GlobalShortcut {
        name: Cfg.KeyBinds.toggleBackendTester
        description: "Toggle backend tester panel"
        onPressed: root.toggle()
    }

    // ── IPC Handler ───────────────────────────────────────────────────
    IpcHandler {
        target: "backendTesterPanel"

        function toggle(): void { root.toggle() }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
    }

    // ── Listen to BackendService messages for the log tab ─────────────
    Connections {
        target: Svc.BackendService

        function onMessageReceived(module, data) {
            recvLog.append({
                "timestamp": new Date().toLocaleTimeString(),
                "module": module,
                "payload": JSON.stringify(data, null, 2)
            });
        }
    }

    // ── Visibility / Focus management ─────────────────────────────────
    onIsOpenChanged: {
        if (isOpen) {
            requestActivate();
        }
    }

    // ── Toggle functions ──────────────────────────────────────────────
    function toggle() { isOpen = !isOpen }
    function open() { isOpen = true }
    function close() { isOpen = false }

    // ── Log an outgoing message ───────────────────────────────────────
    function logOutgoing(module, payload) {
        let jsonStr = (typeof payload === "string") ? payload : JSON.stringify(payload, null, 2);
        sentLog.append({
            "timestamp": new Date().toLocaleTimeString(),
            "module": module,
            "payload": jsonStr
        });
    }

    // ── Send request and log it ───────────────────────────────────────
    function sendAndLog(module, actionPayload) {
        Svc.BackendService.sendRequest(module, actionPayload);
        logOutgoing(module, { "module": module, "action": actionPayload });
    }

    // ══════════════════════════════════════════════════════════════════
    //  VISUAL CONTENT
    // ══════════════════════════════════════════════════════════════════

    // ── Main container ────────────────────────────────────────────────
    Rectangle {
        id: container
        anchors.fill: parent
        color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.92)
        radius: 12
        border.width: 1
        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.12)

        // ── Content ───────────────────────────────────────────────────
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ══════════════════════════════════════════════════════════
            //  HEADER
            // ══════════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.5)
                radius: 12
                // Only bottom corners rounded (top handled by container)
                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 12; color: parent.color }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8

                    Text {
                        text: "Backend Tester"
                        color: Th.Theme.fg
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Module selector
                    Rectangle {
                        Layout.preferredWidth: moduleSelectorText.width + 32
                        Layout.preferredHeight: 28
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)
                        radius: 14
                        border.width: 1
                        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)

                        Text {
                            id: moduleSelectorText
                            anchors.centerIn: parent
                            text: root.selectedModule + " ▾"
                            color: Th.Theme.primary
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moduleMenuOpen = !root.moduleMenuOpen
                    }

                    // Custom dropdown
                    Column {
                        id: moduleDropdown
                        anchors.top: parent.bottom
                        anchors.topMargin: 4
                        anchors.right: parent.right
                        z: 100
                        visible: root.moduleMenuOpen

                        Repeater {
                            model: moduleModel
                            delegate: Rectangle {
                            required property var modelData

                                width: 120
                                height: 30
                                radius: 6
                                color: moduleArea.containsMouse ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.15) : Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.95)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Th.Theme.fg
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: moduleArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedModule = model.name;
                                        root.moduleMenuOpen = false;
                                    }
                                }
                            }
                        }
                    }

                    }

                    // Connection status indicator
                    RowLayout {
                        spacing: 6

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: Svc.BackendService.isConnected ? Th.Theme.success : Th.Theme.error

                            SequentialAnimation on opacity {
                                running: !Svc.BackendService.isConnected
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                            }
                        }

                        Text {
                            text: Svc.BackendService.isConnected ? "Connected" : "Disconnected"
                            color: Svc.BackendService.isConnected ? Th.Theme.success : Th.Theme.error
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════════
            //  TAB BAR
            // ══════════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.topMargin: 8
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: 6

                    Comp.SidebarTabButton {
                        text: "State"
                        isActive: root.activeTab === 0
                        onClicked: root.activeTab = 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Comp.SidebarTabButton {
                        text: "Actions"
                        isActive: root.activeTab === 1
                        onClicked: root.activeTab = 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Comp.SidebarTabButton {
                        text: "Builder"
                        isActive: root.activeTab === 2
                        onClicked: root.activeTab = 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Comp.SidebarTabButton {
                        text: "Log"
                        isActive: root.activeTab === 3
                        onClicked: root.activeTab = 3
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.preferredHeight: 1
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)
            }

            // ══════════════════════════════════════════════════════════
            //  TAB CONTENT
            // ══════════════════════════════════════════════════════════
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                currentIndex: root.activeTab

                // ─────────────────────────────────────────────────────
                // TAB 0: STATE VIEWER
                // ─────────────────────────────────────────────────────
                StateTab {
                    stateData: Svc.BackendService.networkState
                    moduleName: root.selectedModule
                }

                // ─────────────────────────────────────────────────────
                // TAB 1: QUICK ACTIONS
                // ─────────────────────────────────────────────────────
                ActionsTab {
                    selectedModule: root.selectedModule
                    knownActions: root.knownActions
                    onSendAction: function(module, action, args) {
                        let payload;
                        if (args === "")
                            payload = action;
                        else
                            payload = JSON.parse(args);

                        root.sendAndLog(module, payload);
                    }
                }

                // ─────────────────────────────────────────────────────
                // TAB 2: REQUEST BUILDER
                // ─────────────────────────────────────────────────────
                BuilderTab {
                    selectedModule: root.selectedModule
                    knownActions: root.knownActions
                    onSendRequest: function(module, actionPayload) {
                        root.sendAndLog(module, actionPayload);
                    }
                }

                // ─────────────────────────────────────────────────────
                // TAB 3: MESSAGE LOG
                // ─────────────────────────────────────────────────────
                LogTab {
                    sentModel: sentLog
                    recvModel: recvLog
                    autoScroll: root.autoScroll
                    onAutoScrollToggled: root.autoScroll = value
                    onClearLog: {
                        sentLog.clear();
                        recvLog.clear();
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    //  INLINE TAB COMPONENTS
    // ══════════════════════════════════════════════════════════════════

    // ─────────────────────────────────────────────────────────────────
    // StateTab — structured network state + raw JSON (scrollable)
    // ─────────────────────────────────────────────────────────────────
    component StateTab: Item {
        id: stateTabRoot

        property var stateData: ({})
        property string moduleName: "network"
        property var accessPoints: {
            var aps = stateData.wifi_access_points;
            return (aps && Array.isArray(aps)) ? aps : [];
        }

        // Scrollable container
        Flickable {
            id: stateFlickable
            anchors.fill: parent
            anchors.margins: 12
            contentHeight: stateContent.implicitHeight + 24
            clip: true

            flickDeceleration: 2000
            maximumFlickVelocity: 3000
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: stateContent
                width: parent.width
                spacing: 10

                // ── Status section ────────────────────────────────────────
                Comp.GlassCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: statusCol.implicitHeight + 20

                    ColumnLayout {
                        id: statusCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6

                        Text {
                            text: "Status"
                            color: Th.Theme.primary
                            font.pixelSize: 13
                            font.bold: true
                        }

                        // Wireless enabled
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "Wireless:"; color: Th.Theme.fg; font.pixelSize: 12; font.family: "monospace" }
                            Text {
                                text: stateTabRoot.stateData.wireless_enabled !== undefined
                                      ? (stateTabRoot.stateData.wireless_enabled ? "enabled" : "disabled")
                                      : "—"
                                color: stateTabRoot.stateData.wireless_enabled ? Th.Theme.success : Th.Theme.error
                                font.pixelSize: 12
                                font.family: "monospace"
                                font.weight: Font.Medium
                            }
                            Item { Layout.fillWidth: true }
                        }

                        // Networking enabled
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "Networking:"; color: Th.Theme.fg; font.pixelSize: 12; font.family: "monospace" }
                            Text {
                                text: stateTabRoot.stateData.networking_enabled !== undefined
                                      ? (stateTabRoot.stateData.networking_enabled ? "enabled" : "disabled")
                                      : "—"
                                color: stateTabRoot.stateData.networking_enabled ? Th.Theme.success : Th.Theme.error
                                font.pixelSize: 12
                                font.family: "monospace"
                                font.weight: Font.Medium
                            }
                            Item { Layout.fillWidth: true }
                        }

                        // Connectivity
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "Connectivity:"; color: Th.Theme.fg; font.pixelSize: 12; font.family: "monospace" }
                            Text {
                                text: stateTabRoot.stateData.connectivity !== undefined
                                      ? String(stateTabRoot.stateData.connectivity)
                                      : "—"
                                color: Th.Theme.info
                                font.pixelSize: 12
                                font.family: "monospace"
                            }
                            Item { Layout.fillWidth: true }
                        }

                        // State
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "State:"; color: Th.Theme.fg; font.pixelSize: 12; font.family: "monospace" }
                            Text {
                                text: stateTabRoot.stateData.state !== undefined
                                      ? String(stateTabRoot.stateData.state)
                                      : "—"
                                color: Th.Theme.info
                                font.pixelSize: 12
                                font.family: "monospace"
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // ── Device section ────────────────────────────────────────
                Comp.GlassCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: deviceCol.implicitHeight + 20

                    ColumnLayout {
                        id: deviceCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6

                        Text {
                            text: "Device"
                            color: Th.Theme.primary
                            font.pixelSize: 13
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "Object path:"; color: Th.Theme.fg; font.pixelSize: 12; font.family: "monospace" }
                            Text {
                                text: stateTabRoot.stateData.wifi_device_object_path || "—"
                                color: Th.Theme.secondary
                                font.pixelSize: 11
                                font.family: "monospace"
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // ── Access Points section ─────────────────────────────────
                Comp.GlassCard {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 120
                    // Dynamic height: header (36px) + min(6 APs, count) * ~44px each + margins
                    Layout.preferredHeight: {
                        let count = stateTabRoot.accessPoints.length || 0;
                        if (count === 0) return 120; // Show minimum for empty state
                        let headerHeight = 36;
                        let apItemHeight = 44;
                        let maxVisible = 6;
                        let visibleCount = Math.min(count, maxVisible);
                        let total = headerHeight + (visibleCount * apItemHeight) + 20;
                        return Math.max(total, 120);
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Access Points"
                                color: Th.Theme.primary
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: String(stateTabRoot.accessPoints.length)
                                color: Th.Theme.fg
                                font.pixelSize: 12
                                font.family: "monospace"
                            }
                        }

                        // AP list — ListView for virtualized rendering
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: stateTabRoot.accessPoints

                            delegate: Rectangle {
                                required property var modelData

                                width: ListView.view.width
                                height: apDelegateCol.implicitHeight + 12
                                radius: 6
                                color: modelData.connected
                                       ? Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.08)
                                       : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.03)

                                ColumnLayout {
                                    id: apDelegateCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: modelData.ssid || "Hidden"
                                            color: modelData.connected ? Th.Theme.success : Th.Theme.fg
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.band || ""
                                            color: Th.Theme.info
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                        }

                                        Rectangle {
                                            visible: modelData.secure
                                            Layout.preferredWidth: secureText.contentWidth + 12
                                            Layout.preferredHeight: 16
                                            radius: 8
                                            color: Qt.rgba(Th.Theme.warning.r, Th.Theme.warning.g, Th.Theme.warning.b, 0.15)
                                            Text {
                                                id: secureText
                                                anchors.centerIn: parent
                                                text: "SEC"
                                                color: Th.Theme.warning
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }

                                    // Signal strength bar
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 4
                                            radius: 2
                                            color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

                                            Rectangle {
                                                width: parent.width * (modelData.strength || 0) / 100
                                                height: parent.height
                                                radius: 2
                                                color: (modelData.strength || 0) > 70 ? Th.Theme.success
                                                     : (modelData.strength || 0) > 40 ? Th.Theme.warning
                                                     : Th.Theme.error
                                            }
                                        }

                                        Text {
                                            text: (modelData.strength || 0) + "%"
                                            color: Th.Theme.fg
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                            Layout.preferredWidth: 30
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }

                            // Empty state
                            Text {
                                anchors.centerIn: parent
                                visible: stateTabRoot.accessPoints.length === 0
                                text: "No access points"
                                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                // ── Raw JSON (collapsible) ────────────────────────────────
                Comp.GlassCard {
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6

                        // Header with copy button
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Raw JSON"
                                color: Th.Theme.primary
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: copyBtnWidth.contentWidth + 16
                                height: 24
                                radius: 12
                                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

                                Text {
                                    id: copyBtnWidth
                                    anchors.centerIn: parent
                                    text: "Copy"
                                    color: Th.Theme.secondary
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        rawJsonText.selectAll();
                                        rawJsonText.copy();
                                        rawJsonText.deselect();
                                    }
                                }
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(rawJsonText.contentHeight, 200)
                            contentHeight: rawJsonText.contentHeight
                            clip: true

                            flickDeceleration: 2000
                            maximumFlickVelocity: 3000
                            boundsBehavior: Flickable.StopAtBounds

                            TextEdit {
                                id: rawJsonText
                                width: parent.width
                                text: JSON.stringify(stateTabRoot.stateData, null, 2)
                                color: Th.Theme.secondary
                                font.family: "monospace"
                                font.pixelSize: 11
                                wrapMode: Text.WrapAnywhere
                                readOnly: true
                                selectByMouse: true
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // ActionsTab — one-click action buttons
    // ─────────────────────────────────────────────────────────────────
    component ActionsTab: ColumnLayout {
        id: actionsTabRoot

        property string selectedModule: "network"
        property var knownActions: ({})
        signal sendAction(string module, string action, string args)

        spacing: 12

        Text {
            text: "Quick Actions"
            color: Th.Theme.fg
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            text: "One-click actions for " + actionsTabRoot.selectedModule
            color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
            font.pixelSize: 12
        }

        // Action buttons grid
        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: actionsTabRoot.knownActions[actionsTabRoot.selectedModule] || []

                delegate: Rectangle {
                    required property var modelData

                    width: actionBtnContent.implicitWidth + 24
                    height: 36
                    radius: 18
                    color: actionBtnArea.containsMouse
                           ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.2)
                           : Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.3)

                    scale: actionBtnArea.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: actionBtnContent
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: modelData.argsHint !== "" ? Th.Theme.warning : Th.Theme.success
                        }

                        Text {
                            text: modelData.label
                            color: Th.Theme.primary
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: actionBtnArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionsTabRoot.sendAction(actionsTabRoot.selectedModule, modelData.name, modelData.argsHint);
                        }
                    }
                }
            }
        }

        // ── Connect section (network-specific) ───────────────────
        Rectangle {
            visible: actionsTabRoot.selectedModule === "network"
            Layout.fillWidth: true
            Layout.preferredHeight: connectCol.implicitHeight + 20
            color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.3)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)

            ColumnLayout {
                id: connectCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Connect to Network"
                    color: Th.Theme.fg
                    font.pixelSize: 14
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.12)

                        TextInput {
                            id: ssidInput
                            anchors.fill: parent
                            anchors.margins: 10
                            color: Th.Theme.fg
                            font.pixelSize: 13
                            font.family: "monospace"
                            verticalAlignment: Text.AlignVCenter
                            clip: true

                            Text {
                                anchors.fill: parent
                                text: "SSID"
                                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
                                font.pixelSize: 13
                                visible: ssidInput.text.length === 0
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: connectBtnText.width + 24
                        Layout.preferredHeight: 36
                        radius: 18
                        color: ssidInput.text.length > 0
                               ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.25)
                               : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
                        border.width: 1
                        border.color: ssidInput.text.length > 0
                                      ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.4)
                                      : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
                        enabled: ssidInput.text.length > 0
                        opacity: enabled ? 1.0 : 0.4

                        Text {
                            id: connectBtnText
                            anchors.centerIn: parent
                            text: "Connect"
                            color: ssidInput.text.length > 0 ? Th.Theme.primary : Th.Theme.fg
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: ssidInput.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (ssidInput.text.length > 0) {
                                    let payload = { "connect": { "ssid": ssidInput.text } };
                                    actionsTabRoot.sendAction(actionsTabRoot.selectedModule, "connect", JSON.stringify(payload));
                                    ssidInput.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Status feedback area ──────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.2)
            radius: 8

            Text {
                id: feedbackText
                anchors.centerIn: parent
                text: "Click an action to send a request"
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                font.pixelSize: 12
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ─────────────────────────────────────────────────────────────────
    // BuilderTab — custom JSON request builder
    // ─────────────────────────────────────────────────────────────────
    component BuilderTab: ColumnLayout {
        id: builderTabRoot

        property string selectedModule: "network"
        property var knownActions: ({})
        signal sendRequest(string module, var actionPayload)

        spacing: 10

        Text {
            text: "Request Builder"
            color: Th.Theme.fg
            font.pixelSize: 16
            font.bold: true
        }

        // Module display (read-only, uses panel selector)
        Text {
            text: "Module: " + builderTabRoot.selectedModule
            color: Th.Theme.info
            font.pixelSize: 12
            font.family: "monospace"
        }

        // Action input
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Action"
                color: Th.Theme.fg
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 8
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
                border.width: 1
                border.color: actionInput.activeFocus
                              ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.5)
                              : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.12)

                TextInput {
                    id: actionInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Th.Theme.fg
                    font.pixelSize: 13
                    font.family: "monospace"
                    verticalAlignment: Text.AlignVCenter
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "e.g. toggle_wifi"
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
                        font.pixelSize: 13
                        font.family: "monospace"
                        visible: actionInput.text.length === 0
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Action suggestions
            Flow {
                Layout.fillWidth: true
                spacing: 4
                visible: actionInput.text.length === 0

                Repeater {
                    model: builderTabRoot.knownActions[builderTabRoot.selectedModule] || []

                    delegate: Rectangle {
                        required property var modelData

                        width: sugText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: sugArea.containsMouse
                               ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.15)
                               : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

                        Text {
                            id: sugText
                            anchors.centerIn: parent
                            text: modelData.name
                            color: Th.Theme.secondary
                            font.pixelSize: 10
                            font.family: "monospace"
                        }

                        MouseArea {
                            id: sugArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: actionInput.text = modelData.name
                        }
                    }
                }
            }
        }

        // Args input
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Arguments (JSON)"
                    color: Th.Theme.fg
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: argsValidation.text
                    color: argsValidation.color
                    font.pixelSize: 10
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                radius: 8
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
                border.width: 1
                border.color: argsInput.activeFocus
                              ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.5)
                              : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.12)

                TextEdit {
                    id: argsInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Th.Theme.fg
                    font.pixelSize: 12
                    font.family: "monospace"
                    wrapMode: Text.WrapAnywhere
                    selectByMouse: true

                    Text {
                        anchors.fill: parent
                        text: '{"key": "value"}'
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
                        font.pixelSize: 12
                        font.family: "monospace"
                        visible: argsInput.text.length === 0
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }

            // Validation indicator
            RowLayout {
                Layout.fillWidth: true
                property bool isValid: {
                    if (argsInput.text.trim() === "") return true;
                    try { JSON.parse(argsInput.text); return true; } catch(e) { return false; }
                }

                Rectangle {
                    id: argsValidation
                    property string text: parent.isValid ? (argsInput.text.trim() === "" ? "No args (unit variant)" : "Valid JSON") : "Invalid JSON"
                    Layout.preferredWidth: validIndicator.width + validText.contentWidth + 16
                    Layout.preferredHeight: 18
                    radius: 9
                    color: Qt.rgba(parent.isValid ? Th.Theme.success.r : Th.Theme.error.r,
                                   parent.isValid ? Th.Theme.success.g : Th.Theme.error.g,
                                   parent.isValid ? Th.Theme.success.b : Th.Theme.error.b,
                                   0.1)

                    property color indicatorColor: parent.isValid ? Th.Theme.success : Th.Theme.error

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Rectangle {
                            id: validIndicator
                            width: 6
                            height: 6
                            radius: 3
                            color: argsValidation.indicatorColor
                        }
                        Text {
                            id: validText
                            text: argsValidation.text
                            color: argsValidation.indicatorColor
                            font.pixelSize: 10
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Payload preview section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: previewCol.implicitHeight + 20
            color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.3)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)

            ColumnLayout {
                id: previewCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                // Header with copy button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Payload Preview"
                        color: Th.Theme.primary
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: copyPreviewText.contentWidth + 16
                        Layout.preferredHeight: 24
                        radius: 12
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

                        Text {
                            id: copyPreviewText
                            anchors.centerIn: parent
                            text: "Copy"
                            color: Th.Theme.secondary
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                previewTextEdit.selectAll();
                                previewTextEdit.copy();
                                previewTextEdit.deselect();
                            }
                        }
                    }
                }

                // Scrollable preview area
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(previewTextEdit.contentHeight + 8, 150)
                    contentHeight: previewTextEdit.contentHeight + 8
                    clip: true

                    flickDeceleration: 2000
                    maximumFlickVelocity: 3000
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: previewTextEdit
                        width: parent.width
                        anchors.margins: 4
                        text: builderTabRoot.buildPreview()
                        color: Th.Theme.info
                        font.family: "monospace"
                        font.pixelSize: 11
                        wrapMode: Text.WrapAnywhere
                        readOnly: true
                        selectByMouse: true
                    }
                }
            }
        }

        // Send button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 20
            color: sendArea.containsMouse
                   ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.35)
                   : Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.2)
            border.width: 1
            border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.5)

            scale: sendArea.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "Send Request    Ctrl+Enter"
                color: Th.Theme.primary
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            MouseArea {
                id: sendArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: builderTabRoot.doSend()
            }
        }

        // Ctrl+Enter shortcut
        Shortcut {
            sequence: "Ctrl+Return"
            onActivated: builderTabRoot.doSend()
            enabled: builderTabRoot.visible
        }

        function buildPreview(): string {
            let mod = builderTabRoot.selectedModule;
            let act = actionInput.text.trim();
            let argsStr = argsInput.text.trim();

            if (act === "") return "{ \"module\": \"" + mod + "\", \"action\": \"<action>\" }";

            let actionPayload;
            if (argsStr === "") {
                actionPayload = act;
            } else {
                try {
                    let parsedArgs = JSON.parse(argsStr);
                    let obj = {};
                    obj[act] = parsedArgs;
                    actionPayload = obj;
                } catch (e) {
                    return "Error: " + e.message;
                }
            }

            return JSON.stringify({ "module": mod, "action": actionPayload }, null, 2);
        }

        function doSend() {
            let mod = builderTabRoot.selectedModule;
            let act = actionInput.text.trim();
            let argsStr = argsInput.text.trim();

            if (act === "") return;

            let actionPayload;
            if (argsStr === "") {
                actionPayload = act;
            } else {
                try {
                    let parsedArgs = JSON.parse(argsStr);
                    let obj = {};
                    obj[act] = parsedArgs;
                    actionPayload = obj;
                } catch (e) {
                    return;
                }
            }

            builderTabRoot.sendRequest(mod, actionPayload);
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // LogTab — message history with sent/received columns
    // ─────────────────────────────────────────────────────────────────
    component LogTab: ColumnLayout {
        id: logTabRoot

        property var sentModel
        property var recvModel
        property bool autoScroll: true
        signal autoScrollToggled(bool value)
        signal clearLog()

        spacing: 8

        // Header row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Message Log"
                color: Th.Theme.fg
                font.pixelSize: 16
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Entry counts
            Text {
                text: {
                    let sent = logTabRoot.sentModel ? logTabRoot.sentModel.count : 0;
                    let recv = logTabRoot.recvModel ? logTabRoot.recvModel.count : 0;
                    return "↑" + sent + " ↓" + recv;
                }
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                font.pixelSize: 11
                font.family: "monospace"
            }

            // Auto-scroll toggle
            Rectangle {
                Layout.preferredWidth: autoScrollText.contentWidth + 24
                Layout.preferredHeight: 26
                radius: 13
                color: logTabRoot.autoScroll
                       ? Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.15)
                       : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
                border.width: 1
                border.color: logTabRoot.autoScroll
                              ? Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.3)
                              : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

                Text {
                    id: autoScrollText
                    anchors.centerIn: parent
                    text: logTabRoot.autoScroll ? "Auto-scroll ON" : "Auto-scroll OFF"
                    color: logTabRoot.autoScroll ? Th.Theme.success : Th.Theme.fg
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: logTabRoot.autoScrollToggled(!logTabRoot.autoScroll)
                }
            }

            // Clear log button
            Rectangle {
                Layout.preferredWidth: clearText.contentWidth + 24
                Layout.preferredHeight: 26
                radius: 13
                color: clearArea.containsMouse
                       ? Qt.rgba(Th.Theme.error.r, Th.Theme.error.g, Th.Theme.error.b, 0.2)
                       : Qt.rgba(Th.Theme.error.r, Th.Theme.error.g, Th.Theme.error.b, 0.08)
                border.width: 1
                border.color: Qt.rgba(Th.Theme.error.r, Th.Theme.error.g, Th.Theme.error.b, 0.3)

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear Log"
                    color: Th.Theme.error
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: logTabRoot.clearLog()
                }
            }
        }

        // Two-column layout for sent and received
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Sent messages column
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                // Column header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 6
                    color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.1)
                    border.width: 1
                    border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: "↑ Sent (" + (logTabRoot.sentModel ? logTabRoot.sentModel.count : 0) + ")"
                        color: Th.Theme.primary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                // Sent messages list
                ListView {
                    id: sentListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: logTabRoot.sentModel
                    spacing: 4

                    flickDeceleration: 2000
                    maximumFlickVelocity: 3000
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        required property string timestamp
                        required property string module
                        required property string payload
                        required property int index

                        width: sentListView.width
                        height: sentEntryCol.implicitHeight + 12
                        radius: 6
                        color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.15)

                        ColumnLayout {
                            id: sentEntryCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 3

                            // Header row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: timestamp
                                    color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                }

                                Text {
                                    text: module
                                    color: Th.Theme.secondary
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    font.weight: Font.Medium
                                }

                                Item { Layout.fillWidth: true }

                                // Copy button
                                Text {
                                    text: "Copy"
                                    color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                                    font.pixelSize: 10
                                    visible: sentCopyHover.containsMouse

                                    MouseArea {
                                        id: sentCopyHover
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            sentPayloadText.selectAll();
                                            sentPayloadText.copy();
                                            sentPayloadText.deselect();
                                        }
                                    }
                                }
                            }

                            // Payload (scrollable)
                            Flickable {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(sentPayloadText.contentHeight + 8, 120)
                                contentHeight: sentPayloadText.contentHeight + 8
                                clip: true

                                flickDeceleration: 2000
                                maximumFlickVelocity: 3000
                                boundsBehavior: Flickable.StopAtBounds

                                TextEdit {
                                    id: sentPayloadText
                                    width: parent.width
                                    anchors.margins: 4
                                    text: payload
                                    color: Th.Theme.fg
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    wrapMode: Text.WrapAnywhere
                                    readOnly: true
                                    selectByMouse: true
                                }
                            }
                        }

                        // Click to copy
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: function(mouse) {
                                sentPayloadText.selectAll();
                                sentPayloadText.copy();
                                sentPayloadText.deselect();
                                mouse.accepted = false;
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: logTabRoot.sentModel && logTabRoot.sentModel.count === 0
                        text: "No sent messages"
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Auto-scroll behavior
                    onContentHeightChanged: {
                        if (logTabRoot.autoScroll && contentHeight > height)
                            positionViewAtEnd();
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
            }

            // Received messages column
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                // Column header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 6
                    color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.1)
                    border.width: 1
                    border.color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: "↓ Received (" + (logTabRoot.recvModel ? logTabRoot.recvModel.count : 0) + ")"
                        color: Th.Theme.success
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                // Received messages list
                ListView {
                    id: recvListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: logTabRoot.recvModel
                    spacing: 4

                    flickDeceleration: 2000
                    maximumFlickVelocity: 3000
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        required property string timestamp
                        required property string module
                        required property string payload
                        required property int index

                        width: recvListView.width
                        height: recvEntryCol.implicitHeight + 12
                        radius: 6
                        color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.15)

                        ColumnLayout {
                            id: recvEntryCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 3

                            // Header row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: timestamp
                                    color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                }

                                Text {
                                    text: module
                                    color: Th.Theme.secondary
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    font.weight: Font.Medium
                                }

                                Item { Layout.fillWidth: true }

                                // Copy button
                                Text {
                                    text: "Copy"
                                    color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                                    font.pixelSize: 10
                                    visible: recvCopyHover.containsMouse

                                    MouseArea {
                                        id: recvCopyHover
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            recvPayloadText.selectAll();
                                            recvPayloadText.copy();
                                            recvPayloadText.deselect();
                                        }
                                    }
                                }
                            }

                            // Payload (scrollable)
                            Flickable {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(recvPayloadText.contentHeight + 8, 120)
                                contentHeight: recvPayloadText.contentHeight + 8
                                clip: true

                                flickDeceleration: 2000
                                maximumFlickVelocity: 3000
                                boundsBehavior: Flickable.StopAtBounds

                                TextEdit {
                                    id: recvPayloadText
                                    width: parent.width
                                    anchors.margins: 4
                                    text: payload
                                    color: Th.Theme.fg
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    wrapMode: Text.WrapAnywhere
                                    readOnly: true
                                    selectByMouse: true
                                }
                            }
                        }

                        // Click to copy
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: function(mouse) {
                                recvPayloadText.selectAll();
                                recvPayloadText.copy();
                                recvPayloadText.deselect();
                                mouse.accepted = false;
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: logTabRoot.recvModel && logTabRoot.recvModel.count === 0
                        text: "No received messages"
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Auto-scroll behavior
                    onContentHeightChanged: {
                        if (logTabRoot.autoScroll && contentHeight > height)
                            positionViewAtEnd();
                    }
                }
            }
        }
    }
}
