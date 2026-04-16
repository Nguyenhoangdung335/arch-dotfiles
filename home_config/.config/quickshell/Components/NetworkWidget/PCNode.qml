pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

Rectangle {
  id: root

  property bool isInputtingPassword: false
  property bool isSearching: false
  property string targetSSID: ""

  onIsSearchingChanged: {
    if (!isSearching) {
      searchField.text = "";
    }
  }

  signal connectRequested(string ssid, string password)
  signal inputCancelled
  signal searchCancelled
  signal searchAccepted
  signal searchQueryChanged(string query)

  function requestPassword(ssid: string) {
    targetSSID = ssid;
    isSearching = false;
    isInputtingPassword = true;
    passwordField.forceActiveFocus();
  }

  function focusSearch() {
    isInputtingPassword = false;
    isSearching = true;
    searchField.forceActiveFocus();
  }

  width: (isInputtingPassword || isSearching) ? 220 : 60
  height: 60
  radius: height / 2
  color: "#2E3440"
  border.color: isInputtingPassword ? "#A3BE8C" : (isSearching ? "#EBCB8B" : "#88C0D0")
  border.width: 2

  Behavior on width {
    NumberAnimation {
      duration: 300
      easing.type: Easing.OutBack
    }
  }
  Behavior on border.color {
    ColorAnimation {
      duration: 300
    }
  }

  Text {
    id: pcIcon

    anchors.centerIn: parent
    text: "PC"
    color: "#ECEFF4"
    font.bold: true
    opacity: (root.isInputtingPassword || root.isSearching) ? 0.0 : 1.0

    Behavior on opacity {
      NumberAnimation {
        duration: 200
      }
    }
  }

  TextField {
    id: passwordField

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.verticalCenter: parent.verticalCenter
    visible: root.isInputtingPassword
    opacity: root.isInputtingPassword ? 1.0 : 0.0
    placeholderText: "Password for " + root.targetSSID
    echoMode: TextInput.Password
    color: "#ECEFF4"

    Behavior on opacity {
      NumberAnimation {
        duration: 300
      }
    }
    background: Rectangle {
      color: Qt.rgba(1, 1, 1, 0.05)
      radius: 4
    }

    onAccepted: {
      root.connectRequested(root.targetSSID, text);
      root.isInputtingPassword = false;
      text = "";
    }
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        root.isInputtingPassword = false;
        root.inputCancelled();
        text = "";
        event.accepted = true;
      }
    }
  }

  TextField {
    id: searchField

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.verticalCenter: parent.verticalCenter
    visible: root.isSearching
    opacity: root.isSearching ? 1.0 : 0.0
    placeholderText: "Search SSIDs..."
    color: "#ECEFF4"

    Behavior on opacity {
      NumberAnimation {
        duration: 300
      }
    }
    background: Rectangle {
      color: Qt.rgba(1, 1, 1, 0.05)
      radius: 4
    }

    onTextChanged: {
      root.searchQueryChanged(text);
    }
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        root.isSearching = false;
        text = "";
        root.searchCancelled();
        event.accepted = true;
      } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
        event.accepted = true;
        searchField.focus = false;
        root.searchAccepted();
      }
    }
  }
}
