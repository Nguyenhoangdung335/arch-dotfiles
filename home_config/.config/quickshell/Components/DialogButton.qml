import QtQuick

import "../Themes" as Th

Rectangle {
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
