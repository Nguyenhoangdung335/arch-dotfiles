import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import "../Themes" as Th

Rectangle {
    id: card

    property string thumbnailPath: ""
    property string wallpaperPath: ""
    property string wallpaperName: ""
    property bool isLoading: thumbnail.status === Image.Loading
    signal clicked()

    radius: 12
    color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.5)
    border.width: cardArea.containsMouse ? 2 : 1
    border.color: cardArea.containsMouse
                  ? Th.Theme.primary
                  : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

    clip: false

    Behavior on border.color {
        ColorAnimation { duration: 250 }
    }
    Behavior on border.width {
        NumberAnimation { duration: 200 }
    }

    Item {
        id: imageContainer
        anchors.fill: parent
        anchors.margins: 2

        Image {
            id: thumbnail
            anchors.fill: parent
            source: card.thumbnailPath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 300
            sourceSize.height: 200
            visible: false // Hidden because MultiEffect will render it
            layer.enabled: true // CRITICAL: Required to render invisible item to texture
        }

        Rectangle {
            id: imageMask
            anchors.fill: parent
            radius: card.radius - 2
            visible: false // Hidden because it's just a mask
            layer.enabled: true // CRITICAL: Required for MultiEffect to read it as a texture
        }

        MultiEffect {
            anchors.fill: parent
            source: thumbnail
            maskEnabled: true
            maskSource: imageMask

            opacity: thumbnail.status === Image.Ready ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.8)
        visible: card.isLoading
        radius: card.radius

        opacity: loadingPulse.running ? 0.7 : 1.0

        SequentialAnimation on opacity {
            id: loadingPulse
            running: card.isLoading
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
