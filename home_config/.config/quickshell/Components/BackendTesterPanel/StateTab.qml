import QtQuick
import QtQuick.Layouts
import "../../Themes" as Th
import "../../Components" as Comp
Item {
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

}
