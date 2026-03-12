import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../Themes" as Th
import "../Config" as Cfg
import "../Components" as Comp

Popup {
    id: pathDialog

    anchors.centerIn: parent
    implicitWidth: parent.width - 32
    height: 150
    modal: true

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "scale"
            from: 0.9
            to: 1.0
            duration: 250
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: 150
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            property: "scale"
            from: 1.0
            to: 0.95
            duration: 150
            easing.type: Easing.InCubic
        }
    }

    background: Rectangle {
        color: Th.Theme.surface
        radius: 16
        border.width: 1
        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)

        layer.enabled: true
        layer.effect: ShaderEffect {
            property real shadowOpacity: 0.3
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Wallpaper Directory"
            color: Th.Theme.fg
            font.pixelSize: 16
            font.bold: true
        }

        TextField {
            id: pathInput
            Layout.fillWidth: true
            text: Cfg.Theme.wallpaperDir

            color: Th.Theme.fg
            placeholderText: "/path/to/wallpapers"
            placeholderTextColor: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)

            background: Rectangle {
                color: Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.5)
                radius: 8
                border.width: pathInput.activeFocus ? 2 : 1
                border.color: pathInput.activeFocus
                              ? Th.Theme.primary
                              : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)

                Behavior on border.width {
                    NumberAnimation { duration: 200 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Comp.DialogButton {
                text: "Cancel"
                onClicked: pathDialog.close()
            }

            Comp.DialogButton {
                text: "Save"
                isPrimary: true
                onClicked: {
                    Cfg.Theme.wallpaperDir = pathInput.text;
                    pathDialog.close();
                }
            }
        }
    }
}
