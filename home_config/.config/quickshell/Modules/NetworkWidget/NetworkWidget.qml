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

PanelWindow {
    id: root

    property bool opened: false
    property bool isAnimating: slideAnim.running

    // Widget dimensions
    readonly property int widgetWidth: 350
    readonly property int widgetHeight: 400

    color: "transparent"

    anchors {
        top: true
        right: true
    }
    
    // Add margin to push it below the status bar, assuming status bar is at the top
    margins {
        top: 40
        right: 10
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: root.opened

    // Fixed geometry to prevent Hyprland layer size jumps
    implicitWidth: root.widgetWidth
    implicitHeight: root.widgetHeight

    mask: Region {
        item: contentWrapper
    }

    // Keyboard navigation
    Item {
        anchors.fill: parent
        focus: root.opened

        Shortcut {
            sequences: ["Escape"]
            onActivated: root.close()
            enabled: root.opened
        }
    }

    Item {
        id: contentWrapper
        property bool animationRunning: slideAnim.running

        anchors.left: parent.left
        anchors.right: parent.right

        height: root.widgetHeight
        
        // Slide animation (drawer from top)
        y: root.opened ? 0 : -root.widgetHeight
        clip: false
        enabled: root.opened || root.isAnimating

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: 400
                easing.type: Easing.OutQuint
            }
        }

        // Background
        Rectangle {
            id: blurBackground
            anchors.fill: parent
            radius: 12

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
                blur: root.opened ? 0.5 : 0.0
                saturation: 1.2
            }
        }

        // Content
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: "Network Graph"
                color: Th.Theme.fg
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            }

            // Placeholder for graph
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
                    radius: 8
                    border.width: 1
                    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "Graph Placeholder"
                        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    // Toggle Functions
    function toggle() {
        opened = !opened;
    }

    function open() {
        opened = true;
    }

    function close() {
        opened = false;
    }

    // GlobalShortcut
    GlobalShortcut {
        name: "toggleNetworkWidget"
        description: "Toggle network widget"
        
        onPressed: root.toggle()
    }

    // IPC Handler
    IpcHandler {
        target: "network"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }
}
