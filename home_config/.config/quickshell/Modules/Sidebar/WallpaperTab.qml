pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../../Themes" as Th
import "../../Config" as Cfg
import "../../Services" as Services
import "../../Components" as Comp

Item {
    id: root

    // Reference state from our new WallpaperService
    property bool contentReady: Services.WallpaperService.isReady
    property bool thumbnailsGenerated: !Services.WallpaperService.isGenerating
    
    // We bind directly to the service's ListModel
    property var wallpaperModel: Services.WallpaperService.wallpapers

    function setWallpaper(path: string) {
        Quickshell.execDetached([
            "swww",
            "img", path,
            "--transition-type", "any",
            "--transition-step", "90",
            "--transition-angle", "45",
            "--transition-duration", "1.25",
            "--transition-fps", "120"
        ]);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        opacity: root.contentReady ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        Comp.WallpaperHeader {
            onEditClicked: pathDialog.open()
            
            transform: Translate {
                y: root.contentReady ? 0 : -20
                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }
            }
        }

        Text {
            text: root.wallpaperModel.count + " wallpapers found"
            color: Th.Theme.fg
            opacity: 0.6
            font.pixelSize: 12

            transform: Translate {
                x: root.contentReady ? 0 : -15
                Behavior on x {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Loader {
            id: gridLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.contentReady && root.thumbnailsGenerated
            sourceComponent: wallpaperGridComponent

            onLoaded: {
                item.opacity = 1
            }
        }

        Component {
            id: wallpaperGridComponent

            GridView {
                id: wallpaperGrid
                clip: true

                cellWidth: (width - 8) / 2
                cellHeight: cellWidth * 0.6

                contentWidth: width
                contentHeight: height

                model: root.wallpaperModel

                // Flick handling
                flickDeceleration: 1500
                maximumFlickVelocity: 2500
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                pixelAligned: true
                interactive: true
                pressDelay: 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Comp.WallpaperCard {
                    required property var model
                    required property int index

                    implicitWidth: wallpaperGrid.cellWidth - 8
                    height: wallpaperGrid.cellHeight - 8

                    thumbnailPath: model.thumbnailPath
                    wallpaperPath: model.path
                    wallpaperName: model.name

                    opacity: root.contentReady ? 1 : 0
                    scale: root.contentReady ? 1 : 0.8

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                            property int delay: Math.min(index * 50, 500)
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }

                    onClicked: root.setWallpaper(model.path)
                }

                populate: Transition {
                    NumberAnimation {
                        properties: "opacity,scale"
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                add: Transition {
                    NumberAnimation {
                        properties: "opacity,scale"
                        from: 0
                        to: 1
                        duration: 400
                        easing.type: Easing.OutBack
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        properties: "opacity,scale"
                        to: 0
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.thumbnailsGenerated
            color: "transparent"

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "⏳"
                    font.pixelSize: 24
                }

                Text {
                    text: "Generating thumbnails..."
                    color: Th.Theme.fg
                    font.pixelSize: 14
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.wallpaperModel.count === 0 && root.thumbnailsGenerated

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                scale: emptyAnimation.running ? 1.1 : 1.0

                SequentialAnimation on scale {
                    id: emptyAnimation
                    running: parent.parent.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 1.05
                        duration: 1000
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 1000
                        easing.type: Easing.InOutSine
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "🖼️"
                    font.pixelSize: 48
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No wallpapers found"
                    color: Th.Theme.fg
                    font.pixelSize: 16
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Add images to your wallpaper directory"
                    color: Th.Theme.fg
                    opacity: 0.6
                    font.pixelSize: 13
                }
            }
        }
    }

    Comp.WallpaperPathDialog {
        id: pathDialog
    }
}
