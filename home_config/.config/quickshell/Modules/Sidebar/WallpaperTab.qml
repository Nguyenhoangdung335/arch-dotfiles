pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../../Themes" as Th
import "../../Config" as Cfg
import "../../Services" as Services

Item {
    id: root

    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "gif", "bmp"]
    readonly property string thumbnailSize: "300x200"

    property bool contentReady: false
    property bool thumbnailsGenerated: false

    ListModel {
        id: wallpaperModel
    }

    Process {
        id: thumbnailGen
        running: false
        command: [Quickshell.shellDir + "/scripts/generate-thumbnails.sh", Cfg.Theme.wallpaperDir]
    }

    Timer {
        id: thumbnailTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            root.thumbnailsGenerated = true
            wallpaperScanner.running = true
        }
    }

    function startThumbnailGeneration() {
        thumbnailGen.running = true
        thumbnailTimer.start()
    }

    Process {
        id: wallpaperScanner
        running: false
        command: ["ls", "-1", Cfg.Theme.wallpaperDir]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(data) {
                return root.parseWallpapers(data)
            }
        }
    }

    Connections {
        target: Cfg.Theme
        function onWallpaperDirChanged() {
            root.thumbnailsGenerated = false
            wallpaperModel.clear()
            root.startThumbnailGeneration()
        }
    }

    function parseWallpapers(data: string) {
        const lines = data.trim().split("\n")

        for (const fileName of lines) {
            if (!fileName) continue

            const ext = fileName.split('.').pop().toLowerCase()

            if (root.imageExtensions.includes(ext)) {
                var thumbPath = Services.WallpaperModel.getThumbnailPath(Cfg.Theme.wallpaperDir + "/" + fileName)
                wallpaperModel.append({
                    name: fileName,
                    path: Cfg.Theme.wallpaperDir + "/" + fileName,
                    thumbnailPath: thumbPath
                });
            }
        }

        root.contentReady = true
    }

    function rescanWallpapers() {
        wallpaperScanner.running = true;
    }

    Component.onCompleted: {
        startThumbnailGeneration()
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

        Rectangle {
            Layout.fillWidth: true
            height: 50
            radius: 12
            color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.5)
            border.width: 1
            border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

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

            scale: pathRect.containsMouse ? 1.02 : 1.0
            Behavior on scale {
                SpringAnimation {
                    spring: 3
                    damping: 0.5
                }
            }

            property alias containsMouse: pathRect.containsMouse

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
                    text: root.shortenPath(Cfg.Theme.wallpaperDir)
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
                            root.rescanWallpapers()
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
                        onClicked: pathDialog.open()
                    }
                }
            }
        }

        Text {
            text: wallpaperModel.count + " wallpapers found"
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

                model: wallpaperModel

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

                // WheelHandler {
                //       enabled: true
                //       acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                //       property real wheelScrollMultiplier: 1.5
                //       onWheel: event => {
                //                  const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 2;
                //                  const newY = wallpaperGrid.contentY - (delta * wheelScrollMultiplier);
                //                  wallpaperGrid.contentY = Math.max(0, Math.min(newY, wallpaperGrid.contentHeight - wallpaperGrid.height));
                //                  event.accepted = true;
                //                }
                //     }

                delegate: WallpaperCard {
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
            visible: wallpaperModel.count === 0 && root.thumbnailsGenerated

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

                DialogButton {
                    text: "Cancel"
                    onClicked: pathDialog.close()
                }

                DialogButton {
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

    function shortenPath(path: string): string {
        var home = Quickshell.env("HOME");
        if (path.startsWith(home)) {
            return "~" + path.substring(home.length);
        }
        return path;
    }

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

    component WallpaperCard: Rectangle {
        id: card

        property string thumbnailPath: ""
        property string wallpaperPath: ""
        property string wallpaperName: ""
        signal clicked()

        radius: 12
        color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.5)
        border.width: cardArea.containsMouse ? 2 : 1
        border.color: cardArea.containsMouse
                      ? Th.Theme.primary
                      : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

        clip: true

        Behavior on border.color {
            ColorAnimation { duration: 250 }
        }
        Behavior on border.width {
            NumberAnimation { duration: 200 }
        }

        Image {
            id: thumbnail
            anchors.fill: parent
            anchors.margins: 2
            source: card.thumbnailPath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 300
            sourceSize.height: 200

            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }

            layer.enabled: true
            layer.effect: ShaderEffect {
                property real radius: (card.radius - 2) / Math.max(thumbnail.width, thumbnail.height)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.8)
            visible: thumbnail.status === Image.Loading
            radius: card.radius

            opacity: loadingPulse.running ? 0.7 : 1.0

            SequentialAnimation on opacity {
                id: loadingPulse
                // running: parent.visible
                running: wallpaperModel.count === 0 && root.thumbnailsGenerated
                loops: Animation.Infinite

                NumberAnimation { to: 0.5; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }

            Text {
                anchors.centerIn: parent
                text: "⏳"
                font.pixelSize: 24
            }
        }

        Rectangle {
            id: nameOverlay
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 32
            radius: card.radius

            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: parent.radius
                color: parent.color
            }

            color: Qt.rgba(0, 0, 0, cardArea.containsMouse ? 0.8 : 0.6)

            Behavior on color {
                ColorAnimation { duration: 250 }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 16
                text: card.wallpaperName
                color: "#ffffff"
                font.pixelSize: 11
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }
        }

        MouseArea {
            id: cardArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.clicked()
        }

        scale: cardArea.pressed ? 0.93 : (cardArea.containsMouse ? 1.05 : 1.0)

        Behavior on scale {
            SpringAnimation {
                spring: 3.5
                damping: 0.35
                epsilon: 0.001
            }
        }

        rotation: cardArea.containsMouse ? 1 : 0
        Behavior on rotation {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.width: cardArea.containsMouse ? 1 : 0
            border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.3)
            opacity: cardArea.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }
    }

    component DialogButton: Rectangle {
        id: dialogBtn

        property string text: ""
        property bool isPrimary: false
        signal clicked()

        implicitWidth: btnText.width + 24
        height: 36
        radius: 8

        color: isPrimary
               ? Th.Theme.primary
               : dialogBtnArea.containsMouse
                 ? Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
                 : "transparent"

        border.width: isPrimary ? 0 : 1
        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)

        Behavior on color {
            ColorAnimation { duration: 250 }
        }

        scale: dialogBtnArea.pressed ? 0.95 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: btnText
            anchors.centerIn: parent
            text: dialogBtn.text
            color: dialogBtn.isPrimary ? Th.Theme.bg : Th.Theme.fg
            font.pixelSize: 14
            font.weight: Font.Medium

            Behavior on color {
                ColorAnimation { duration: 250 }
            }
        }

        MouseArea {
            id: dialogBtnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dialogBtn.clicked()
        }
    }
}
