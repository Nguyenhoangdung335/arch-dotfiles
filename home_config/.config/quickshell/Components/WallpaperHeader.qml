import QtQuick
import QtQuick.Layouts
import Quickshell

import "../Themes" as Th
import "../Config" as Cfg
import "../Services" as Services

Rectangle {
    id: header

    Layout.fillWidth: true
    height: 50
    radius: 12
    color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.5)
    border.width: 1
    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
    
    signal editClicked()

    function shortenPath(path: string): string {
        var home = Quickshell.env("HOME");
        if (path.startsWith(home)) {
            return "~" + path.substring(home.length);
        }
        return path;
    }

    scale: pathRect.containsMouse ? 1.02 : 1.0
    Behavior on scale {
        SpringAnimation {
            spring: 3
            damping: 0.5
        }
    }

    MouseArea {
        id: pathRect
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
            text: "📁"
            font.pixelSize: 18
        }

        Text {
            Layout.fillWidth: true
            text: header.shortenPath(Cfg.Theme.wallpaperDir)
            color: Th.Theme.fg
            font.pixelSize: 13
            elide: Text.ElideMiddle
        }

        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 14
            color: refreshArea.containsMouse
                   ? Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)
                   : "transparent"

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            scale: refreshArea.containsMouse ? 1.1 : 1.0
            Behavior on scale {
                SpringAnimation {
                    spring: 4
                    damping: 0.3
                }
            }

            Text {
                anchors.centerIn: parent
                text: "🔄"
                font.pixelSize: 14

                rotation: refreshArea.clicked ? 360 : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                id: refreshArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                property bool clicked: false

                onClicked: {
                    Services.WallpaperService.rescan()
                    clicked = true
                    Qt.callLater(function() { clicked = false })
                }
            }
        }

        Rectangle {
            implicitWidth: 28
            height: 28
            radius: 14
            color: editArea.containsMouse
                   ? Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)
                   : "transparent"

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            scale: editArea.containsMouse ? 1.1 : 1.0
            Behavior on scale {
                SpringAnimation {
                    spring: 4
                    damping: 0.3
                }
            }

            Text {
                anchors.centerIn: parent
                text: "✏️"
                font.pixelSize: 14
            }

            MouseArea {
                id: editArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: header.editClicked()
            }
        }
    }
}
