import QtQuick
import QtQuick.Layouts
import "../../Themes" as Th
import "../../Components" as Comp
ColumnLayout {
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

}
