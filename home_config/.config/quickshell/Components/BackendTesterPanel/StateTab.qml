pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../Themes" as Th
import "../../Components" as Comp

Item {
  id: stateTabRoot

  property var stateData: ({})
  property string moduleName: "network"

  // Computed property: list of keys in stateData
  readonly property var stateKeys: {
    if (!stateData || typeof stateData !== "object")
      return [];
    return Object.keys(stateData).filter(k => stateData[k] !== undefined);
  }

  Flickable {
    id: stateFlickable

    property real splitMin: 80
    property real splitMax: stateFlickable.height - 86
    property real splitPosition: (stateFlickable.height - 6) / 2

    anchors.fill: parent
    anchors.margins: 12
    contentHeight: stateFlickable.height
    clip: true
    flickDeceleration: 2000
    maximumFlickVelocity: 3000
    boundsBehavior: Flickable.StopAtBounds

    Column {
      width: parent.width
      height: stateFlickable.height

      // ── Dynamic key-value section ─────────────────────────
      Comp.GlassCard {
        width: parent.width
        height: stateFlickable.splitPosition

        Flickable {
          id: kvFlickable

          anchors.fill: parent
          contentHeight: keyValueCol.implicitHeight + 20
          clip: true
          flickDeceleration: 2000
          maximumFlickVelocity: 3000
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: keyValueCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 6

            Text {
              text: "State"
              color: Th.Theme.primary
              font.pixelSize: 13
              font.bold: true
            }

            Repeater {
              model: stateTabRoot.stateKeys

              delegate: ColumnLayout {
                id: stateEntry

                required property string modelData
                required property int index
                property var value: stateTabRoot.stateData[modelData]
                property string valueType: {
                  if (value === null || value === undefined)
                    return "null";
                  if (typeof value === "boolean")
                    return "bool";
                  if (typeof value === "number")
                    return "number";
                  if (typeof value === "string")
                    return "string";
                  if (Array.isArray(value))
                    return "array";
                  if (typeof value === "object")
                    return "object";
                  return "unknown";
                }

                spacing: 4
                Layout.fillWidth: true

                // Bool values
                RowLayout {
                  visible: parent.valueType === "bool"
                  Layout.fillWidth: true
                  spacing: 8

                  Text {
                    text: stateEntry.modelData + ":"
                    color: Th.Theme.fg
                    font.pixelSize: 12
                    font.family: "monospace"
                  }

                  Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: stateEntry.value ? Th.Theme.success : Th.Theme.error
                  }

                  Text {
                    text: stateEntry.value ? "enabled" : "disabled"
                    color: stateEntry.value ? Th.Theme.success : Th.Theme.error
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.weight: Font.Medium
                  }

                  Item {
                    Layout.fillWidth: true
                  }
                }

                // Number values
                RowLayout {
                  visible: parent.valueType === "number"
                  Layout.fillWidth: true
                  spacing: 8

                  Text {
                    text: stateEntry.modelData + ":"
                    color: Th.Theme.fg
                    font.pixelSize: 12
                    font.family: "monospace"
                  }

                  Text {
                    text: String(stateEntry.value)
                    color: Th.Theme.info
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.weight: Font.Medium
                  }

                  Item {
                    Layout.fillWidth: true
                  }
                }

                // String values
                RowLayout {
                  visible: parent.valueType === "string"
                  Layout.fillWidth: true
                  spacing: 8

                  Text {
                    text: stateEntry.modelData + ":"
                    color: Th.Theme.fg
                    font.pixelSize: 12
                    font.family: "monospace"
                  }

                  Text {
                    text: stateEntry.value !== undefined ? String(stateEntry.value) : ""
                    color: Th.Theme.secondary
                    font.pixelSize: 12
                    font.family: "monospace"
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                  }
                }

                // ── Array values - expandable ──
                ColumnLayout {
                  id: arraySection

                  property bool arrayExpanded: true
                  property real arrayContentHeight: arrayExpanded ? arrayContentCol.implicitHeight : 0

                  visible: parent.valueType === "array"
                  Layout.fillWidth: true
                  spacing: 4

                  Behavior on arrayContentHeight {
                    NumberAnimation {
                      duration: 200
                      easing.type: Easing.OutCubic
                    }
                  }

                  // Header row - entire row clickable
                  MouseArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    cursorShape: Qt.PointingHandCursor

                    onClicked: arraySection.arrayExpanded = !arraySection.arrayExpanded

                    RowLayout {
                      anchors.fill: parent
                      spacing: 6

                      Text {
                        text: arraySection.arrayExpanded ? "▾" : "▸"
                        color: Th.Theme.fg
                        font.pixelSize: 10
                      }

                      Text {
                        text: stateEntry.modelData + ":"
                        color: Th.Theme.fg
                        font.pixelSize: 12
                        font.family: "monospace"
                      }

                      Rectangle {
                        Layout.preferredWidth: arrayBadgeText.contentWidth + 12
                        Layout.preferredHeight: 18
                        radius: 9
                        color: Qt.rgba(Th.Theme.warning.r, Th.Theme.warning.g, Th.Theme.warning.b, 0.15)

                        Text {
                          id: arrayBadgeText

                          anchors.centerIn: parent
                          text: "Array[" + stateEntry.value.length + "]"
                          color: Th.Theme.warning
                          font.pixelSize: 10
                          font.weight: Font.Bold
                        }
                      }

                      Item {
                        Layout.fillWidth: true
                      }
                    }
                  }

                  // Expandable content
                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: arraySection.arrayContentHeight
                    clip: true

                    ColumnLayout {
                      id: arrayContentCol

                      anchors.left: parent.left
                      anchors.right: parent.right
                      spacing: 4

                      Repeater {
                        model: stateEntry.value.length

                        delegate: ColumnLayout {
                          id: arrayItemDelegate

                          required property int modelData
                          property var item: stateEntry.value[modelData]
                          property string itemType: {
                            if (item === null || item === undefined)
                              return "null";
                            if (typeof item === "object")
                              return "object";
                            return "primitive";
                          }
                          property bool itemExpanded: false
                          property real itemContentHeight: itemExpanded ? itemContentCol.implicitHeight : 0

                          Layout.fillWidth: true
                          spacing: 2

                          Behavior on itemContentHeight {
                            NumberAnimation {
                              duration: 200
                              easing.type: Easing.OutCubic
                            }
                          }

                          // Object items in array - expandable
                          ColumnLayout {
                            visible: arrayItemDelegate.itemType === "object"
                            Layout.fillWidth: true
                            spacing: 2

                            // Object header row - entire row clickable
                            MouseArea {
                              Layout.fillWidth: true
                              Layout.preferredHeight: 22
                              cursorShape: Qt.PointingHandCursor

                              onClicked: arrayItemDelegate.itemExpanded = !arrayItemDelegate.itemExpanded

                              RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                spacing: 6

                                Text {
                                  text: arrayItemDelegate.itemExpanded ? "▾" : "▸"
                                  color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
                                  font.pixelSize: 10
                                }

                                Text {
                                  text: "Item " + arrayItemDelegate.modelData
                                  color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                                  font.pixelSize: 10
                                  font.family: "monospace"
                                }

                                Text {
                                  text: arrayItemDelegate.item.ssid || arrayItemDelegate.item.name || arrayItemDelegate.item.label || ""
                                  color: Th.Theme.fg
                                  font.pixelSize: 11
                                  font.weight: Font.Medium
                                  elide: Text.ElideRight
                                  Layout.fillWidth: true
                                }

                                Text {
                                  visible: arrayItemDelegate.item.strength !== undefined
                                  text: (arrayItemDelegate.item.strength !== undefined ? arrayItemDelegate.item.strength : 0) + "%"
                                  color: (arrayItemDelegate.item.strength || 0) > 70 ? Th.Theme.success : (arrayItemDelegate.item.strength || 0) > 40 ? Th.Theme.warning : Th.Theme.error
                                  font.pixelSize: 10
                                  font.family: "monospace"
                                }

                                Text {
                                  visible: arrayItemDelegate.item.band !== undefined
                                  text: arrayItemDelegate.item.band !== undefined ? arrayItemDelegate.item.band : ""
                                  color: Th.Theme.info
                                  font.pixelSize: 10
                                  font.family: "monospace"
                                }

                                Rectangle {
                                  visible: arrayItemDelegate.item.secure != undefined && arrayItemDelegate.item.secure !== null
                                  Layout.preferredWidth: itemSecText.contentWidth + 10
                                  Layout.preferredHeight: 14
                                  radius: 7
                                  color: Qt.rgba(Th.Theme.warning.r, Th.Theme.warning.g, Th.Theme.warning.b, 0.15)

                                  Text {
                                    id: itemSecText

                                    anchors.centerIn: parent
                                    text: "SEC"
                                    color: Th.Theme.warning
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                  }
                                }
                              }
                            }

                            // Expandable object content
                            Item {
                              Layout.fillWidth: true
                              Layout.preferredHeight: arrayItemDelegate.itemContentHeight
                              clip: true

                              ColumnLayout {
                                id: itemContentCol

                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 2

                                Repeater {
                                  model: arrayItemDelegate.item !== null && arrayItemDelegate.item !== undefined ? Object.keys(arrayItemDelegate.item) : []

                                  delegate: RowLayout {
                                    id: objEntry

                                    required property string modelData
                                    property var nestedValue: arrayItemDelegate.item[modelData]

                                    Layout.fillWidth: true
                                    anchors.leftMargin: 32
                                    spacing: 6

                                    Text {
                                      text: objEntry.modelData + ":"
                                      color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.5)
                                      font.pixelSize: 10
                                      font.family: "monospace"
                                    }

                                    Text {
                                      text: (objEntry.nestedValue === null || objEntry.nestedValue === undefined) ? "null" : String(objEntry.nestedValue)
                                      color: Th.Theme.secondary
                                      font.pixelSize: 10
                                      font.family: "monospace"
                                      elide: Text.ElideMiddle
                                      Layout.fillWidth: true
                                    }
                                  }
                                }
                              }
                            }
                          }

                          // Primitive items in array
                          RowLayout {
                            visible: arrayItemDelegate.itemType !== "object"
                            Layout.fillWidth: true
                            Layout.leftMargin: 16
                            spacing: 8

                            Text {
                              text: "[" + stateEntry.modelData + "]"
                              color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.4)
                              font.pixelSize: 10
                              font.family: "monospace"
                            }

                            Text {
                              text: arrayItemDelegate.item !== undefined ? String(arrayItemDelegate.item) : ""
                              color: Th.Theme.secondary
                              font.pixelSize: 11
                              font.family: "monospace"
                              elide: Text.ElideMiddle
                              Layout.fillWidth: true
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // ── Object values - expandable ──
                ColumnLayout {
                  id: objectSection

                  property bool objectExpanded: false
                  property real objectContentHeight: objectExpanded ? objContentCol.implicitHeight : 0

                  visible: parent.valueType === "object"
                  Layout.fillWidth: true
                  spacing: 4

                  Behavior on objectContentHeight {
                    NumberAnimation {
                      duration: 200
                      easing.type: Easing.OutCubic
                    }
                  }

                  // Header row - entire row clickable
                  MouseArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    cursorShape: Qt.PointingHandCursor

                    onClicked: objectSection.objectExpanded = !objectSection.objectExpanded

                    RowLayout {
                      anchors.fill: parent
                      spacing: 6

                      Text {
                        text: objectSection.objectExpanded ? "▾" : "▸"
                        color: Th.Theme.fg
                        font.pixelSize: 10
                      }

                      Text {
                        text: stateEntry.modelData + ":"
                        color: Th.Theme.fg
                        font.pixelSize: 12
                        font.family: "monospace"
                      }

                      Rectangle {
                        Layout.preferredWidth: objBadgeText.contentWidth + 12
                        Layout.preferredHeight: 18
                        radius: 9
                        color: Qt.rgba(Th.Theme.info.r, Th.Theme.info.g, Th.Theme.info.b, 0.15)

                        Text {
                          id: objBadgeText

                          anchors.centerIn: parent
                          text: "Object{" + Object.keys(stateEntry.value).length + "}"
                          color: Th.Theme.info
                          font.pixelSize: 10
                          font.weight: Font.Bold
                        }
                      }

                      Item {
                        Layout.fillWidth: true
                      }
                    }
                  }

                  // Expandable content
                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: objectSection.objectContentHeight
                    clip: true

                    ColumnLayout {
                      id: objContentCol

                      anchors.left: parent.left
                      anchors.right: parent.right
                      spacing: 4

                      Repeater {
                        model: Object.keys(stateEntry.value)

                        delegate: RowLayout {
                          id: objEntry2

                          required property string modelData
                          property var nestedValue: stateEntry.value[modelData]

                          Layout.fillWidth: true
                          Layout.leftMargin: 16
                          spacing: 6

                          Text {
                            text: stateEntry.modelData + ":"
                            color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.6)
                            font.pixelSize: 10
                            font.family: "monospace"
                          }

                          Text {
                            text: (objEntry2.nestedValue === null || objEntry2.nestedValue === undefined) ? "null" : String(objEntry2.nestedValue)
                            color: Th.Theme.secondary
                            font.pixelSize: 10
                            font.family: "monospace"
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                          }
                        }
                      }
                    }
                  }
                }

                // Null/undefined values
                RowLayout {
                  visible: parent.valueType === "null"
                  Layout.fillWidth: true
                  spacing: 8

                  Text {
                    text: stateEntry.modelData + ":"
                    color: Th.Theme.fg
                    font.pixelSize: 12
                    font.family: "monospace"
                  }

                  Text {
                    text: "null"
                    color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.italic: true
                  }

                  Item {
                    Layout.fillWidth: true
                  }
                }

                // Separator between entries
                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 1
                  color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.06)
                }
              }
            }

            // Empty state
            Text {
              visible: stateTabRoot.stateKeys.length === 0
              text: "No state data"
              color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.3)
              font.pixelSize: 12
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }
      }

      // ── Resizable divider ────────────────────────────────
      Rectangle {
        id: splitDivider

        width: parent.width
        height: 6
        color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.08)

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          width: 40
          height: 2
          radius: 1
          color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.2)
        }

        MouseArea {
          property real pressY: 0

          anchors.fill: parent
          cursorShape: Qt.SplitVCursor

          onPressed: mouse => pressY = mouse.y
          onPositionChanged: mouse => {
            let delta = mouse.y - pressY;
            stateFlickable.splitPosition += delta;
            stateFlickable.splitPosition = Math.max(stateFlickable.splitMin, Math.min(stateFlickable.splitMax, stateFlickable.splitPosition));
            pressY = mouse.y;
          }
        }
      }

      // ── Raw JSON section ─────────────────────────────────
      Comp.GlassCard {
        width: parent.width
        height: stateFlickable.height - stateFlickable.splitPosition - splitDivider.height

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 6

          RowLayout {
            Layout.fillWidth: true

            Text {
              text: "Raw JSON"
              color: Th.Theme.primary
              font.pixelSize: 13
              font.bold: true
            }

            Item {
              Layout.fillWidth: true
            }

            Rectangle {
              Layout.preferredWidth: copyBtnWidth.contentWidth + 16
              Layout.preferredHeight: 24
              radius: 12
              color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.06)
              border.width: 1
              border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)

              Text {
                id: copyBtnWidth

                anchors.centerIn: parent
                text: "Copy"
                color: Th.Theme.secondary
                font.pixelSize: 11
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                  rawJsonText.selectAll();
                  rawJsonText.copy();
                  rawJsonText.deselect();
                }
              }
            }
          }

          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: rawJsonText.contentHeight + 8
            clip: true
            flickDeceleration: 2000
            maximumFlickVelocity: 3000
            boundsBehavior: Flickable.StopAtBounds

            TextEdit {
              id: rawJsonText

              width: parent.width
              anchors.margins: 4
              text: JSON.stringify(stateTabRoot.stateData, null, 2)
              color: Th.Theme.secondary
              font.family: "monospace"
              font.pixelSize: 11
              wrapMode: Text.WrapAnywhere
              readOnly: true
              selectByMouse: true
            }
          }
        }
      }
    }
  }
}
