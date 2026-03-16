import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import "../../Services" as Svc

PanelWindow {
    id: root
    focusable: true
    
    // Dock to the left side of the screen
    anchors {
        left: true
        top: true
        bottom: true
    }
    
    width: 400
    color: "#1e1e2e" // Dark Catppuccin base color

    // Wrap in a ScrollView in case the state JSON gets very long
    ScrollView {
        anchors.fill: parent
        anchors.margins: 15
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ==========================================
            // HEADER & CONNECTION STATUS
            // ==========================================
            Text {
                text: "Rust Backend IPC Tester"
                font.pixelSize: 20
                font.bold: true
                color: "#cdd6f4"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 5
                // Check if socket is connected (assuming backendSocket is exposed, or just rely on a default)
                // For safety, we just display a static UI or a state derived from Backend if you added a connected property.
                color: "#313244"
                
                Text {
                    anchors.centerIn: parent
                    text: "Socket Status: Check Console"
                    color: "#a6adc8"
                }
            }

            // ==========================================
            // LIVE STATE VIEWER
            // ==========================================
            Text {
                text: "Live Network State:"
                font.pixelSize: 16
                font.bold: true
                color: "#89b4fa" // Blue
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 150
                color: "#11111b"
                radius: 5
                border.color: "#45475a"
                border.width: 1

                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#a6e3a1" // Green
                    font.family: "monospace"
                    wrapMode: Text.WrapAnywhere
                    // Automatically stringifies the Backend var every time it updates!
                    text: JSON.stringify(Svc.BackendService.networkState, null, 2)
                }
            }

            // ==========================================
            // COMMAND BUILDER FORM
            // ==========================================
            Text {
                text: "Send Command:"
                font.pixelSize: 16
                font.bold: true
                color: "#f38ba8" // Red
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // 1. Module Input
                TextField {
                    id: modInput
                    Layout.fillWidth: true
                    placeholderText: "Module (e.g. network)"
                    text: "network"
                    color: "#cdd6f4"
                    background: Rectangle { color: "#313244"; radius: 4 }
                }

                // 2. Action Input
                TextField {
                    id: actInput
                    Layout.fillWidth: true
                    placeholderText: "Action (e.g. toggle_wifi or connect)"
                    color: "#cdd6f4"
                    background: Rectangle { color: "#313244"; radius: 4 }
                }

                // 3. Arguments Input (Optional)
                TextArea {
                    id: argsInput
                    Layout.fillWidth: true
                    Layout.minimumHeight: 80
                    placeholderText: "Args (JSON format)\nLeave empty if no args.\nExample: {\"ssid\": \"MyNetwork\"}"
                    color: "#cdd6f4"
                    font.family: "monospace"
                    wrapMode: TextEdit.Wrap
                    background: Rectangle { color: "#313244"; radius: 4 }
                }

                // 4. Send Button
                Button {
                    Layout.fillWidth: true
                    text: "SEND PAYLOAD"
                    
                    background: Rectangle {
                        color: parent.down ? "#b4befe" : "#89b4fa"
                        radius: 5
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#11111b"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        buildAndSend();
                    }
                }
            }

            // ==========================================
            // ACTION LOG
            // ==========================================
            Text {
                text: "Sent Log:"
                font.pixelSize: 14
                color: "#bac2de"
            }

            Text {
                id: logOutput
                Layout.fillWidth: true
                color: "#f9e2af" // Yellow
                font.family: "monospace"
                wrapMode: Text.WrapAnywhere
                text: "Awaiting input..."
            }
        }
    }

    // ==========================================
    // LOGIC FOR CONSTRUCTING JSON FOR RUST
    // ==========================================
    function buildAndSend() {
        let mod = modInput.text.trim();
        let act = actInput.text.trim();
        let argsStr = argsInput.text.trim();

        if (mod === "" || act === "") {
            logOutput.text = "Error: Module and Action cannot be empty.";
            logOutput.color = "#f38ba8"; // Red
            return;
        }

        let actionPayload;

        if (argsStr === "") {
            // Rust enum without data: NetworkAction::ToggleWifi
            // Serde expects: "toggle_wifi"
            actionPayload = act;
        } else {
            // Rust enum with data: NetworkAction::Connect { ssid: String }
            // Serde expects: {"connect": {"ssid": "MyNetwork"}}
            try {
                let parsedArgs = JSON.parse(argsStr);
                actionPayload = {};
                actionPayload[act] = parsedArgs;
            } catch (e) {
                logOutput.text = "Error: Arguments must be valid JSON.\n" + e.message;
                logOutput.color = "#f38ba8";
                return;
            }
        }

        // Send to Svc.BackendService.qml
        Svc.BackendService.sendRequest(mod, actionPayload);

        // Update visual log
        logOutput.color = "#a6e3a1"; // Green
        logOutput.text = "Sent at " + new Date().toLocaleTimeString() + ":\n" + 
                         JSON.stringify({ module: mod, action: actionPayload }, null, 2);
    }
}
