pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../Themes" as Th

ColumnLayout {
  id: builderTabRoot

  property var knownActions: ({})
  property string selectedModule: "network"

  signal sendRequest(string module, var actionPayload)

  function buildPayload(): var {
    let mod = builderTabRoot.selectedModule;
    let act = actionInput.text.trim();
    let argsStr = argsInput.text.trim();

    if (act === "")
      return null;

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
        return null;
      }
    }

    return {
      "module": mod,
      "action": actionPayload
    };
  }

  function buildPreview(): string {
    let payload = builderTabRoot.buildPayload();
    if (payload === null) {
      let mod = builderTabRoot.selectedModule;
      let act = actionInput.text.trim();
      if (act === "")
        return "{ \"module\": \"" + mod + "\", \"action\": \"<action>\" }";
      let argsStr = argsInput.text.trim();
      if (argsStr !== "") {
        try {
          JSON.parse(argsStr);
        } catch (e) {
          return "Error: " + e.message;
        }
      }
      return "{ \"module\": \"" + mod + "\", \"action\": \"" + act + "\" }";
    }
    return JSON.stringify(payload, null, 2);
  }

  function doSend() {
    let payload = builderTabRoot.buildPayload();
    if (payload === null)
      return;
    builderTabRoot.sendRequest(payload.module, payload.action);
  }

  spacing: 10

  Text {
    color: Th.Theme.fg
    font.bold: true
    font.pixelSize: 16
    text: "Request Builder"
  }

  // Module display (read-only, uses panel selector)
  Text {
    color: Th.Theme.info
    font.family: "monospace"
    font.pixelSize: 12
    text: "Module: " + builderTabRoot.selectedModule
  }

  // Action input
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 4

    Text {
      color: Th.Theme.fg
      font.pixelSize: 12
      text: "Action"
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 36
      border.color: actionInput.activeFocus ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.5) : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.12)
      border.width: 1
      color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
      radius: 8

      TextInput {
        id: actionInput

        anchors.fill: parent
        anchors.margins: 10
        clip: true
        color: Th.Theme.fg
        font.family: "monospace"
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter

        Text {
          anchors.fill: parent
          color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
          font.family: "monospace"
          font.pixelSize: 13
          text: "e.g. toggle_wifi"
          verticalAlignment: Text.AlignVCenter
          visible: actionInput.text.length === 0
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
          id: sugBtn

          required property var modelData

          border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
          border.width: 1
          color: sugArea.containsMouse ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.15) : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.04)
          height: 24
          radius: 12
          width: sugText.implicitWidth + 16

          Text {
            id: sugText

            anchors.centerIn: parent
            color: Th.Theme.secondary
            font.family: "monospace"
            font.pixelSize: 10
            text: sugBtn.modelData.name
          }

          MouseArea {
            id: sugArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: actionInput.text = sugBtn.modelData.name
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
        color: Th.Theme.fg
        font.pixelSize: 12
        text: "Arguments (JSON)"
      }

      Item {
        Layout.fillWidth: true
      }

      Text {
        color: argsValidation.color
        font.pixelSize: 10
        text: argsValidation.text
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 100
      border.color: argsInput.activeFocus ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.5) : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.12)
      border.width: 1
      color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.05)
      radius: 8

      TextEdit {
        id: argsInput

        anchors.fill: parent
        anchors.margins: 10
        color: Th.Theme.fg
        font.family: "monospace"
        font.pixelSize: 12
        selectByMouse: true
        wrapMode: Text.WrapAnywhere

        Text {
          anchors.fill: parent
          color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
          font.family: "monospace"
          font.pixelSize: 12
          text: '{"key": "value"}'
          visible: argsInput.text.length === 0
          wrapMode: Text.WrapAnywhere
        }
      }
    }

    // Validation indicator
    RowLayout {
      property bool isValid: {
        if (argsInput.text.trim() === "")
          return true;
        try {
          JSON.parse(argsInput.text);
          return true;
        } catch (e) {
          return false;
        }
      }

      Layout.fillWidth: true

      Rectangle {
        id: argsValidation

        property color indicatorColor: parent.isValid ? Th.Theme.success : Th.Theme.error
        property string text: parent.isValid ? (argsInput.text.trim() === "" ? "No args (unit variant)" : "Valid JSON") : "Invalid JSON"

        Layout.preferredHeight: 18
        Layout.preferredWidth: validIndicator.width + validText.contentWidth + 16
        color: Qt.rgba(parent.isValid ? Th.Theme.success.r : Th.Theme.error.r, parent.isValid ? Th.Theme.success.g : Th.Theme.error.g, parent.isValid ? Th.Theme.success.b : Th.Theme.error.b, 0.1)
        radius: 9

        RowLayout {
          anchors.centerIn: parent
          spacing: 4

          Rectangle {
            id: validIndicator

            Layout.preferredHeight: 6
            Layout.preferredWidth: 6
            color: argsValidation.indicatorColor
            radius: 3
          }

          Text {
            id: validText

            color: argsValidation.indicatorColor
            font.pixelSize: 10
            text: argsValidation.text
          }
        }
      }

      Item {
        Layout.fillWidth: true
      }
    }
  }

  // Payload preview section
  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: previewCol.implicitHeight + 20
    border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)
    border.width: 1
    color: Qt.rgba(Th.Theme.surface.r, Th.Theme.surface.g, Th.Theme.surface.b, 0.3)
    radius: 10

    ColumnLayout {
      id: previewCol

      anchors.left: parent.left
      anchors.margins: 12
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 8

      // Header with copy button
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          color: Th.Theme.primary
          font.bold: true
          font.pixelSize: 13
          text: "Payload Preview"
        }

        Item {
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.preferredHeight: 24
          Layout.preferredWidth: copyPreviewText.contentWidth + 16
          border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
          border.width: 1
          color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.06)
          radius: 12

          Text {
            id: copyPreviewText

            anchors.centerIn: parent
            color: Th.Theme.secondary
            font.pixelSize: 11
            text: "Copy"
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
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        contentHeight: previewTextEdit.contentHeight + 8
        flickDeceleration: 2000
        maximumFlickVelocity: 3000

        TextEdit {
          id: previewTextEdit

          anchors.margins: 4
          color: Th.Theme.info
          font.family: "monospace"
          font.pixelSize: 11
          readOnly: true
          selectByMouse: true
          text: builderTabRoot.buildPreview()
          width: parent.width
          wrapMode: Text.WrapAnywhere
        }
      }
    }
  }

  // Send button
  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 40
    border.color: Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.5)
    border.width: 1
    color: sendArea.containsMouse ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.35) : Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.2)
    radius: 20
    scale: sendArea.pressed ? 0.97 : 1.0

    Behavior on color {
      ColorAnimation {
        duration: 150
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: 100
        easing.type: Easing.OutCubic
      }
    }

    Text {
      anchors.centerIn: parent
      color: Th.Theme.primary
      font.pixelSize: 14
      font.weight: Font.Bold
      text: "Send Request    Ctrl+Enter"
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
    enabled: builderTabRoot.visible
    sequence: "Ctrl+Return"

    onActivated: builderTabRoot.doSend()
  }
}
