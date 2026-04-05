import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    
    property bool isInputtingPassword: false
    property string targetSSID: ""
    
    signal connectRequested(string ssid, string password)
    signal inputCancelled()
    
    width: isInputtingPassword ? 220 : 60
    height: 60
    radius: height / 2
    color: "#2E3440"
    border.color: isInputtingPassword ? "#A3BE8C" : "#88C0D0"
    border.width: 2
    
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
    Behavior on border.color { ColorAnimation { duration: 300 } }
    
    // The default icon/text
    Text {
        id: pcIcon
        anchors.centerIn: parent
        text: "PC"
        color: "#ECEFF4"
        font.bold: true
        opacity: root.isInputtingPassword ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    
    // The password input field
    TextField {
        id: passwordField
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        
        visible: root.isInputtingPassword || root.width > 120
        opacity: root.isInputtingPassword ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        placeholderText: "Password for " + root.targetSSID
        echoMode: TextInput.Password
        color: "#ECEFF4"
        background: Item {} // Transparent background
        
        onAccepted: {
            root.connectRequested(root.targetSSID, text)
            root.isInputtingPassword = false
            text = ""
        }
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.isInputtingPassword = false
                root.inputCancelled()
                text = ""
                event.accepted = true
            }
        }
    }
    
    function requestPassword(ssid) {
        targetSSID = ssid
        isInputtingPassword = true
        passwordField.forceActiveFocus()
    }
}
