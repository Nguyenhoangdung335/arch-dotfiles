pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../Themes" as Th

ColumnLayout {
  id: logTabRoot

  property var sentModel
  property var recvModel
  property bool autoScroll: true

  signal autoScrollToggled(bool value)
  signal clearLog

  spacing: 8

  // Header row
  RowLayout {
    Layout.fillWidth: true
    spacing: 8

    Text {
      text: "Message Log"
      color: Th.Theme.fg
      font.pixelSize: 16
      font.bold: true
    }

    Item {
      Layout.fillWidth: true
    }

    // Entry counts
    Text {
      text: {
        let sent = logTabRoot.sentModel ? logTabRoot.sentModel.count : 0;
        let recv = logTabRoot.recvModel ? logTabRoot.recvModel.count : 0;
        return "↑" + sent + " ↓" + recv;
      }
      color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
      font.pixelSize: 11
      font.family: "monospace"
    }

    // Auto-scroll toggle
    Rectangle {
      Layout.preferredWidth: autoScrollText.contentWidth + 24
      Layout.preferredHeight: 26
      radius: 13
      color: logTabRoot.autoScroll ? Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.15) : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
      border.width: 1
      border.color: logTabRoot.autoScroll ? Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.3) : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

      Text {
        id: autoScrollText

        anchors.centerIn: parent
        text: logTabRoot.autoScroll ? "Auto-scroll ON" : "Auto-scroll OFF"
        color: logTabRoot.autoScroll ? Th.Theme.success : Th.Theme.fg
        font.pixelSize: 10
        font.weight: Font.Medium
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: logTabRoot.autoScrollToggled(!logTabRoot.autoScroll)
      }
    }

    // Clear log button
    Rectangle {
      Layout.preferredWidth: clearText.contentWidth + 24
      Layout.preferredHeight: 26
      radius: 13
      color: clearArea.containsMouse ? Qt.rgba(Th.Theme.error.r, Th.Theme.error.g, Th.Theme.error.b, 0.2) : Qt.rgba(Th.Theme.error.r, Th.Theme.error.g, Th.Theme.error.b, 0.08)
      border.width: 1
      border.color: Qt.rgba(Th.Theme.error.r, Th.Theme.error.g, Th.Theme.error.b, 0.3)

      Text {
        id: clearText

        anchors.centerIn: parent
        text: "Clear Log"
        color: Th.Theme.error
        font.pixelSize: 10
        font.weight: Font.Medium
      }

      MouseArea {
        id: clearArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: logTabRoot.clearLog()
      }
    }
  }

  // Two-column layout for sent and received
  RowLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 8

    // Sent messages column
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 4

      // Column header
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 6
        color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.1)
        border.width: 1
        border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.2)

        Text {
          anchors.centerIn: parent
          text: "↑ Sent (" + (logTabRoot.sentModel ? logTabRoot.sentModel.count : 0) + ")"
          color: Th.Theme.primary
          font.pixelSize: 12
          font.weight: Font.Medium
        }
      }

      // Sent messages list
      ListView {
        id: sentListView

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: logTabRoot.sentModel
        spacing: 4
        flickDeceleration: 2000
        maximumFlickVelocity: 3000
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
          id: sentEntry

          required property string timestamp
          required property string module
          required property string payload
          required property int index

          width: sentListView.width
          height: sentEntryCol.implicitHeight + 12
          radius: 6
          color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.06)
          border.width: 1
          border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.15)

          ColumnLayout {
            id: sentEntryCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 3

            // Header row
            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: sentEntry.timestamp
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
                font.pixelSize: 10
                font.family: "monospace"
              }

              Text {
                text: sentEntry.module
                color: Th.Theme.secondary
                font.pixelSize: 10
                font.family: "monospace"
                font.weight: Font.Medium
              }

              Item {
                Layout.fillWidth: true
              }

              // Copy button
              Text {
                text: "Copy"
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                font.pixelSize: 10
                visible: sentCopyHover.containsMouse

                MouseArea {
                  id: sentCopyHover

                  anchors.fill: parent
                  anchors.margins: -4
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onClicked: {
                    sentPayloadText.selectAll();
                    sentPayloadText.copy();
                    sentPayloadText.deselect();
                  }
                }
              }
            }

            // Payload (scrollable)
            Flickable {
              Layout.fillWidth: true
              Layout.preferredHeight: Math.min(sentPayloadText.contentHeight + 8, 120)
              contentHeight: sentPayloadText.contentHeight + 8
              clip: true
              flickDeceleration: 2000
              maximumFlickVelocity: 3000
              boundsBehavior: Flickable.StopAtBounds

              TextEdit {
                id: sentPayloadText

                width: parent.width
                anchors.margins: 4
                text: sentEntry.payload
                color: Th.Theme.fg
                font.family: "monospace"
                font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
                readOnly: true
                selectByMouse: true
              }
            }
          }

          // Click to copy
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true

            onClicked: function (mouse) {
              sentPayloadText.selectAll();
              sentPayloadText.copy();
              sentPayloadText.deselect();
              mouse.accepted = false;
            }
          }
        }

        // Auto-scroll behavior
        onContentHeightChanged: {
          if (logTabRoot.autoScroll && contentHeight > height)
            positionViewAtEnd();
        }

        // Empty state
        Text {
          anchors.centerIn: parent
          visible: logTabRoot.sentModel && logTabRoot.sentModel.count === 0
          text: "No sent messages"
          color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
          font.pixelSize: 11
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    // Divider
    Rectangle {
      Layout.preferredWidth: 1
      Layout.fillHeight: true
      color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
    }

    // Received messages column
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 4

      // Column header
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 6
        color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.1)
        border.width: 1
        border.color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.2)

        Text {
          anchors.centerIn: parent
          text: "↓ Received (" + (logTabRoot.recvModel ? logTabRoot.recvModel.count : 0) + ")"
          color: Th.Theme.success
          font.pixelSize: 12
          font.weight: Font.Medium
        }
      }

      // Received messages list
      ListView {
        id: recvListView

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: logTabRoot.recvModel
        spacing: 4
        flickDeceleration: 2000
        maximumFlickVelocity: 3000
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
          id: recvEntry

          required property string timestamp
          required property string module
          required property string payload
          required property int index

          width: recvListView.width
          height: recvEntryCol.implicitHeight + 12
          radius: 6
          color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.06)
          border.width: 1
          border.color: Qt.rgba(Th.Theme.success.r, Th.Theme.success.g, Th.Theme.success.b, 0.15)

          ColumnLayout {
            id: recvEntryCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 3

            // Header row
            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: recvEntry.timestamp
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
                font.pixelSize: 10
                font.family: "monospace"
              }

              Text {
                text: recvEntry.module
                color: Th.Theme.secondary
                font.pixelSize: 10
                font.family: "monospace"
                font.weight: Font.Medium
              }

              Item {
                Layout.fillWidth: true
              }

              // Copy button
              Text {
                text: "Copy"
                color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                font.pixelSize: 10
                visible: recvCopyHover.containsMouse

                MouseArea {
                  id: recvCopyHover

                  anchors.fill: parent
                  anchors.margins: -4
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onClicked: {
                    recvPayloadText.selectAll();
                    recvPayloadText.copy();
                    recvPayloadText.deselect();
                  }
                }
              }
            }

            // Payload (scrollable)
            Flickable {
              Layout.fillWidth: true
              Layout.preferredHeight: Math.min(recvPayloadText.contentHeight + 8, 120)
              contentHeight: recvPayloadText.contentHeight + 8
              clip: true
              flickDeceleration: 2000
              maximumFlickVelocity: 3000
              boundsBehavior: Flickable.StopAtBounds

              TextEdit {
                id: recvPayloadText

                width: parent.width
                anchors.margins: 4
                text: recvEntry.payload
                color: Th.Theme.fg
                font.family: "monospace"
                font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
                readOnly: true
                selectByMouse: true
              }
            }
          }

          // Click to copy
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true

            onClicked: function (mouse) {
              recvPayloadText.selectAll();
              recvPayloadText.copy();
              recvPayloadText.deselect();
              mouse.accepted = false;
            }
          }
        }

        // Auto-scroll behavior
        onContentHeightChanged: {
          if (logTabRoot.autoScroll && contentHeight > height)
            positionViewAtEnd();
        }

        // Empty state
        Text {
          anchors.centerIn: parent
          visible: logTabRoot.recvModel && logTabRoot.recvModel.count === 0
          text: "No received messages"
          color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
          font.pixelSize: 11
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
