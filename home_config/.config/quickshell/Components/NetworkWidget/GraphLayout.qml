pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "."
import "../../Services" as Svc

FocusScope {
  id: root

  // Properties to control the layout
  property bool opened: false
  property ListModel accessPointsModel: null
  property int currentIndex: -1
  property string searchQuery: ""
  property string searchQueryLower: searchQuery.toLowerCase()

  // Graph configuration
  property real radiusBase: Math.min(width, height) / 3

  // Zoom state
  property bool isZoomed: false
  property var selectedNodeData: null

  clip: true

  onOpenedChanged: {
    if (opened) {
      root.forceActiveFocus();
      searchField.text = "";
      searchQuery = "";
      isZoomed = false;
      selectedNodeData = null;
    } else {
      currentIndex = -1;
    }
  }
  Keys.onPressed: event => {
    if ((event.modifiers & Qt.ControlModifier)) {
      if (event.key === Qt.Key_N) {
        if (nodeRepeater.count > 0) {
          currentIndex = (currentIndex + 1) % nodeRepeater.count;
        }
        event.accepted = true;
      } else if (event.key === Qt.Key_P) {
        if (nodeRepeater.count > 0) {
          currentIndex = (currentIndex - 1 + nodeRepeater.count) % nodeRepeater.count;
        }
        event.accepted = true;
      } else if (event.key === Qt.Key_F) {
        searchField.visible = true;
        searchField.forceActiveFocus();
        event.accepted = true;
      }
    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
      if (currentIndex >= 0 && currentIndex < nodeRepeater.count) {
        let item = nodeRepeater.itemAt(currentIndex);
        if (item) {
          root.isZoomed = true;
          let modelData = root.accessPointsModel.get(currentIndex);
          if (modelData) {
            root.selectedNodeData = {
              ssid: modelData.ssid !== undefined ? modelData.ssid : "Unknown",
              strength: modelData.strength !== undefined ? modelData.strength : 0,
              connected: modelData.connected !== undefined ? modelData.connected : false
            };
          }
        }
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Escape) {
      if (root.isZoomed) {
        root.isZoomed = false;
        root.selectedNodeData = null;
        root.forceActiveFocus();
        event.accepted = true;
      } else if (searchField.visible) {
        searchField.visible = false;
        searchField.text = "";
        searchQuery = "";
        root.forceActiveFocus();
        event.accepted = true;
      }
    }
  }

  Item {
    id: graphContainer

    anchors.fill: parent

    transform: [
      Translate {
        id: graphTranslate

        // When zoomed, center the selected node (by shifting graph container)
        // Assuming selected node is at (targetX, targetY).
        // Target is parent.width/2, parent.height/2. But wait, if selected node is at targetX, targetY,
        // and we want it to move to left side or center, we offset it. Let's move it to center-left
        property real targetXShift: {
          if (root.isZoomed && root.currentIndex >= 0 && root.currentIndex < nodeRepeater.count) {
            let node = nodeRepeater.itemAt(root.currentIndex);
            if (node) {
              return (root.width * 0.3) - (node.targetX + node.width / 2);
            }
          }
          return 0;
        }
        property real targetYShift: {
          if (root.isZoomed && root.currentIndex >= 0 && root.currentIndex < nodeRepeater.count) {
            let node = nodeRepeater.itemAt(root.currentIndex);
            if (node) {
              return (root.height / 2) - (node.targetY + node.height / 2);
            }
          }
          return 0;
        }

        x: targetXShift
        y: targetYShift

        Behavior on x {
          NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
          }
        }
        Behavior on y {
          NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
          }
        }
      },
      Scale {
        id: graphScale

        origin.x: root.width / 2
        origin.y: root.height / 2
        // We could also set origin to the selected node so it zooms into it
        // origin.x: { ... }
        // For now, scale and translate separate is fine
        xScale: root.isZoomed ? 1.5 : 1.0
        yScale: root.isZoomed ? 1.5 : 1.0

        Behavior on xScale {
          NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
          }
        }
        Behavior on yScale {
          NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
          }
        }
      }
    ]

    // Active Edge between PC and current selection
    ActiveEdge {
      id: activeEdge

      sourceNode: pcNode
      targetNode: root.currentIndex >= 0 && root.currentIndex < nodeRepeater.count ? nodeRepeater.itemAt(root.currentIndex) : null
      z: 0
    }

    // PC Node in center
    PCNode {
      id: pcNode

      x: parent.width / 2 - width / 2
      y: parent.height / 2 - height / 2
      z: 10

      onConnectRequested: (ssid, password) => {
        Svc.NetworkService.connectToNetwork(ssid, password);
        root.forceActiveFocus();
      }
      onInputCancelled: root.forceActiveFocus()
    }

    // Repeater for Network Nodes
    Repeater {
      id: nodeRepeater

      model: root.accessPointsModel

      delegate: NetworkNode {
        id: networkNode

        required property var modelData
        required property int index
        property bool matchesSearch: root.searchQuery === "" || ssid.toLowerCase().indexOf(root.searchQueryLower) !== -1
        property real baseAngle: (index / Math.max(1, nodeRepeater.count)) * 2 * Math.PI - Math.PI / 2
        property real angleOffset: {
          if (root.currentIndex === -1 || nodeRepeater.count < 3)
            return 0;

          let dist = Math.abs(index - root.currentIndex);
          if (dist > nodeRepeater.count / 2) {
            dist = nodeRepeater.count - dist;
          }

          if (dist === 1) {
            let sign = (index > root.currentIndex) ? 1 : -1;

            if (index === 0 && root.currentIndex === nodeRepeater.count - 1)
              sign = 1;
            if (index === nodeRepeater.count - 1 && root.currentIndex === 0)
              sign = -1;

            return sign * 0.2;
          }
          return 0;
        }
        property real angle: baseAngle + angleOffset
        property real r: root.radiusBase + (100 - strength) / 2

        ssid: modelData.ssid !== undefined ? modelData.ssid : "Unknown"
        strength: modelData.strength !== undefined ? modelData.strength : 0
        connected: modelData.connected !== undefined ? modelData.connected : false
        isCurrent: modelData.connected
        opened: root.opened
        isFocused: index === root.currentIndex
        opacity: opened ? (matchesSearch ? 1.0 : 0.2) : 0.0
        targetX: parent.width / 2 + r * Math.cos(angle) - width / 2
        targetY: parent.height / 2 + r * Math.sin(angle) - height / 2
        z: isFocused || isHovered ? 5 : 1

        onClicked: {
          root.currentIndex = index;
          root.isZoomed = true;
          root.selectedNodeData = {
            ssid: networkNode.ssid,
            strength: networkNode.strength,
            connected: networkNode.connected
          };
        }
        onIsHoveredChanged: {
          if (isHovered && !root.isZoomed) {
            root.currentIndex = index;
          }
        }
      }
    }
  }

  // The Drawer
  Loader {
    id: detailDrawerLoader

    active: root.selectedNodeData !== null
    anchors.fill: parent

    sourceComponent: Component {
      NetworkDetailDrawer {
        opened: root.isZoomed
        networkData: root.selectedNodeData

        onCloseRequested: {
          root.isZoomed = false;
          root.forceActiveFocus();
        }
        onConnectRequested: ssid => {
          pcNode.requestPassword(ssid);
        }
      }
    }
  }

  // Search Field Overlay
  TextField {
    id: searchField

    visible: false
    anchors.top: parent.top
    anchors.topMargin: 20
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width * 0.6
    placeholderText: "Search SSIDs... (Esc to close)"

    onTextChanged: {
      root.searchQuery = text;
      if (text !== "") {
        for (let i = 0; i < nodeRepeater.count; i++) {
          let item = nodeRepeater.itemAt(i);
          if (item && item.matchesSearch) {
            root.currentIndex = i;
            break;
          }
        }
      }
    }
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        visible = false;
        text = "";
        root.searchQuery = "";
        root.forceActiveFocus();
        event.accepted = true;
      } else if ((event.modifiers & Qt.ControlModifier)) {
        if (event.key === Qt.Key_N) {
          if (nodeRepeater.count > 0) {
            let start = (root.currentIndex + 1) % nodeRepeater.count;
            for (let i = 0; i < nodeRepeater.count; i++) {
              let idx = (start + i) % nodeRepeater.count;
              let item = nodeRepeater.itemAt(idx);
              if (item && item.matchesSearch) {
                root.currentIndex = idx;
                break;
              }
            }
          }
          event.accepted = true;
        } else if (event.key === Qt.Key_P) {
          if (nodeRepeater.count > 0) {
            let start = (root.currentIndex - 1 + nodeRepeater.count) % nodeRepeater.count;
            for (let i = 0; i < nodeRepeater.count; i++) {
              let idx = (start - i + nodeRepeater.count) % nodeRepeater.count;
              let item = nodeRepeater.itemAt(idx);
              if (item && item.matchesSearch) {
                root.currentIndex = idx;
                break;
              }
            }
          }
          event.accepted = true;
        }
      }
    }
  }
}
