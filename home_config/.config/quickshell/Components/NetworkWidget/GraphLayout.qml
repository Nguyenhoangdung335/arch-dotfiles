pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "."
import "../../Services" as Svc
import "../../Config" as Config

FocusScope {
  id: root

  HoverHandler {
    acceptedDevices: PointerDevice.Mouse
    onPointChanged: root.usingKeyboardNav = false
  }

  // Properties to control the layout
  property bool opened: false
  property ListModel accessPointsModel: null
  property int currentIndex: -1
  property string searchQuery: ""
  property string searchQueryLower: searchQuery.toLowerCase()
  property double lastKeyboardNavTime: 0
  property bool usingKeyboardNav: false

  // Zoom state
  property bool isZoomed: false
  property bool hasActiveOverlay: pcNode.isSearching || isZoomed
  property var selectedNodeData: null
  property real minZoom: 0.75
  property real maxZoom: 3.0

  // Pannable Universe Config
  property int offsetMaxPannable: 100
  property int mapSize: (sunflowerMinRadius + sunflowerC * Math.sqrt(Math.max(1, accessPointsModel ? accessPointsModel.count : 1)) + offsetMaxPannable) * 2
  property int orbitDurationPerCycle: 300000

  // Sunflower Math Config
  property real sunflowerC: 45 // Distance multiplier
  property real sunflowerMinRadius: 80 + Math.max(0, (pcNode.width - 60) / 2) // Minimum distance from center

  property real globalAngleOffset: 0
  property real spreadFactor: opened ? 1.0 : 0.0
  property real zoomLevel: 1.0

  function calculateSunflowerCoords(index) {
    // Golden angle in radians
    const goldenAngle = Math.PI * (3 - Math.sqrt(5)); // ≈ 2.399963229728653

    // Angle: index * golden angle + global rotation
    let angle = (index * goldenAngle) + root.globalAngleOffset;

    // Radius: scales with square root of index
    let radius = (root.sunflowerMinRadius + root.sunflowerC * Math.sqrt(index)) * root.spreadFactor;

    // Calculate final X and Y relative to map center
    let centerX = root.mapSize / 2;
    let centerY = root.mapSize / 2;

    return {
      x: centerX + radius * Math.cos(angle),
      y: centerY + radius * Math.sin(angle)
    };
  }

  clip: true

  NumberAnimation on globalAngleOffset {
    from: 0
    to: Math.PI * 2
    duration: root.orbitDurationPerCycle
    loops: Animation.Infinite
    running: root.opened
  }
  Behavior on spreadFactor {
    SpringAnimation {
      spring: 2.0
      velocity: 50.0
      damping: 0.25
    }
  }

  onOpenedChanged: {
    if (opened) {
      root.forceActiveFocus();
      pcNode.isSearching = false;
      searchQuery = "";
      isZoomed = false;
      selectedNodeData = null;
      root.zoomLevel = 1.0;
      graphContainer.contentX = (root.mapSize * root.zoomLevel - graphContainer.width) / 2;
      graphContainer.contentY = (root.mapSize * root.zoomLevel - graphContainer.height) / 2;
    } else {
      pcNode.isSearching = false;
      currentIndex = -1;
      root.zoomLevel = 1.0;
      graphContainer.contentX = (root.mapSize * root.zoomLevel - graphContainer.width) / 2;
      graphContainer.contentY = (root.mapSize * root.zoomLevel - graphContainer.height) / 2;
    }
  }
  Keys.onPressed: event => {
    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
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
      }
    }
  }

  Flickable {
    id: graphContainer

    function ensureVisible(idx) {
      if (idx < 0 || idx >= nodeRepeater.count)
        return;
      let node = nodeRepeater.itemAt(idx);
      if (!node)
        return;

      // Smoothly pan flickable to keep node centered
      let targetCX = (node.targetX + node.width / 2) * root.zoomLevel - graphContainer.width / 2;
      let targetCY = (node.targetY + node.height / 2) * root.zoomLevel - graphContainer.height / 2;

      graphContainer.contentX = Math.max(0, Math.min(targetCX, graphContainer.contentWidth - graphContainer.width));
      graphContainer.contentY = Math.max(0, Math.min(targetCY, graphContainer.contentHeight - graphContainer.height));
    }

    anchors.fill: parent
    contentWidth: root.mapSize * root.zoomLevel
    contentHeight: root.mapSize * root.zoomLevel
    interactive: true
    clip: true

    Behavior on contentX {
      enabled: !graphContainer.dragging && !graphContainer.flicking
      NumberAnimation {
        duration: 300
        easing.type: Easing.OutCubic
      }
    }
    Behavior on contentY {
      enabled: !graphContainer.dragging && !graphContainer.flicking
      NumberAnimation {
        duration: 300
        easing.type: Easing.OutCubic
      }
    }

    contentItem.transform: [
      Scale {
        id: graphScale

        origin.x: 0
        origin.y: 0
        xScale: root.zoomLevel
        yScale: root.zoomLevel

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

    // Center on PC node initially
    Component.onCompleted: {
      contentX = (root.mapSize * root.zoomLevel - root.width) / 2;
      contentY = (root.mapSize * root.zoomLevel - root.height) / 2;
    }

    Timer {
      interval: 16
      running: root.opened && root.isZoomed
      repeat: true

      onTriggered: {
        if (root.currentIndex >= 0 && root.currentIndex < nodeRepeater.count) {
          let node = nodeRepeater.itemAt(root.currentIndex);
          if (node) {
            graphContainer.contentX = (node.targetX + node.width / 2) * root.zoomLevel - graphContainer.width * 0.3;
            graphContainer.contentY = (node.targetY + node.height / 2) * root.zoomLevel - graphContainer.height / 2;
          }
        }
      }
    }

    WheelHandler {
      id: wheelHandler

      acceptedDevices: PointerDevice.Mouse

      onWheel: event => {
        let wheel_delta = event.angleDelta.y / 120;
        let step = 0.1;
        if (wheel_delta > 0) {
          root.zoomLevel = Math.min(root.maxZoom, root.zoomLevel + step);
          event.accepted = true;
        } else if (wheel_delta < 0) {
          root.zoomLevel = Math.max(root.minZoom, root.zoomLevel - step);
          event.accepted = true;
        }
      }
    }

    PinchHandler {
      id: pinchHandler

      target: null // We handle zoom manually

      onActiveChanged: {
        if (!active)
          return;
      }
      onScaleChanged: {
        let zoom_delta = scale - 1.0;
        let newZoom = root.zoomLevel + zoom_delta * 0.1;
        root.zoomLevel = Math.max(root.minZoom, Math.min(root.maxZoom, newZoom));
      }
    }

    Shortcut {
      sequence: Config.KeyBinds.networkNextNode

      onActivated: {
        root.lastKeyboardNavTime = Date.now();
        root.usingKeyboardNav = true;
        if (nodeRepeater.count > 0) {
          if (pcNode.isSearching) {
            let start = (root.currentIndex + 1) % nodeRepeater.count;
            for (let i = 0; i < nodeRepeater.count; i++) {
              let idx = (start + i) % nodeRepeater.count;
              let item = nodeRepeater.itemAt(idx);
              if (item && item.matchesSearch) {
                root.currentIndex = idx;
                break;
              }
            }
          } else {
            root.currentIndex = (root.currentIndex + 1) % nodeRepeater.count;
          }
          graphContainer.ensureVisible(root.currentIndex);
        }
      }
    }

    Shortcut {
      sequence: Config.KeyBinds.networkPrevNode

      onActivated: {
        root.lastKeyboardNavTime = Date.now();
        root.usingKeyboardNav = true;
        if (nodeRepeater.count > 0) {
          if (pcNode.isSearching) {
            let start = (root.currentIndex - 1 + nodeRepeater.count) % nodeRepeater.count;
            for (let i = 0; i < nodeRepeater.count; i++) {
              let idx = (start - i + nodeRepeater.count) % nodeRepeater.count;
              let item = nodeRepeater.itemAt(idx);
              if (item && item.matchesSearch) {
                root.currentIndex = idx;
                break;
              }
            }
          } else {
            root.currentIndex = (root.currentIndex - 1 + nodeRepeater.count) % nodeRepeater.count;
          }
          graphContainer.ensureVisible(root.currentIndex);
        }
      }
    }

    Shortcut {
      sequence: Config.KeyBinds.networkSearch

      onActivated: {
        if (pcNode.isSearching) {
          pcNode.isSearching = false;
          root.searchQuery = "";
          root.forceActiveFocus();
        } else {
          pcNode.focusSearch();
        }
      }
    }

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

      x: root.mapSize / 2 - width / 2
      y: root.mapSize / 2 - height / 2
      z: 10

      onIsSearchingChanged: {
        if (isSearching) {
          root.isZoomed = false;
          root.currentIndex = -1;
          graphContainer.contentX = (root.mapSize * root.zoomLevel - graphContainer.width) / 2;
          graphContainer.contentY = (root.mapSize * root.zoomLevel - graphContainer.height) / 2;
        }
      }

      onConnectRequested: (ssid, password) => {
        Svc.NetworkService.connectToNetwork(ssid, password);
        root.forceActiveFocus();
      }
      onInputCancelled: root.forceActiveFocus()
      onSearchCancelled: {
        root.searchQuery = "";
        root.forceActiveFocus();
      }
      onSearchQueryChanged: query => {
        root.searchQuery = query;
        if (query !== "") {
          for (let i = 0; i < nodeRepeater.count; i++) {
            let item = nodeRepeater.itemAt(i);
            if (item && item.matchesSearch) {
              root.currentIndex = i;
              break;
            }
          }
        }
      }
      onSearchAccepted: {
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
        root.forceActiveFocus();
      }
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
        property point coords: root.calculateSunflowerCoords(index)

        ssid: modelData.ssid !== undefined ? modelData.ssid : "Unknown"
        strength: modelData.strength !== undefined ? modelData.strength : 0
        connected: modelData.connected !== undefined ? modelData.connected : false
        isCurrent: modelData.connected
        opened: root.opened
        isFocused: index === root.currentIndex
        keyboardNavActive: root.usingKeyboardNav
        opacity: opened ? (matchesSearch ? 1.0 : 0.2) : 0.0
        targetX: coords.x - width / 2
        targetY: coords.y - height / 2
        z: isFocused || effectivelyHovered ? 5 : 1

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
          if (root.usingKeyboardNav) return; // Ignore hover right after keypress
          if (isHovered && !root.isZoomed) {
            root.currentIndex = index;
          } else if (!isHovered && !root.isZoomed && root.currentIndex === index) {
            root.currentIndex = -1;
          }
        }
      }
    }
  }

  // The Drawer
  Loader {
    id: detailDrawerLoader

    active: root.selectedNodeData !== null
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: item ? item.width : 0

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


}
