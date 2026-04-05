import QtQuick
import QtQuick.Layouts
import "../../Themes" as Th
import "../../Components" as Comp
ColumnLayout {
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

}
