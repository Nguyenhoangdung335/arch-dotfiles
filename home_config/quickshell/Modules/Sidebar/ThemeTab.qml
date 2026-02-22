// ./Modules/Sidebar/ThemeTab.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../Themes" as Th
import "../../Config" as Cfg
import "../../Services" as Svc
// import "../../Models" as Models
// import "../../JSUtils/Logging.js" as Logging

// Theme palette selection tab with smooth animations
Item {
    id: root
    
    // ✨ Animation state
    property bool contentReady: false
    
    property var groupedModel: [] 

    function rebuildGroupedModel() {
        var familyMap = {};

        for (var i = 0; i < Svc.ThemeModel.count; i++) {
            var currPaletteName = Svc.ThemeModel.dataName.get(i);
            var currPaletteObj = Svc.ThemeModel.dataMap[currPaletteName.displayName];

            var family = currPaletteObj.family;
            var variant = currPaletteObj.variant;

            if (!familyMap[family]) {
                familyMap[family] = [];
            }
            
            familyMap[family].push(currPaletteObj);
        }
        
        var tempGroups = [];
        for (var fam in familyMap) {
            var variantsArray = familyMap[fam].map(function(obj) {
                var safePreviewColors = [];
                for (var p = 0; p < obj.previewColors.length; p++) {
                    safePreviewColors.push(obj.previewColors[p]);
                }

                var safeColors = [];
                for (var c = 0; c < obj.colors.length; c++) {
                    var colorItem = obj.colors[c];
                    safeColors.push({
                        "name": colorItem.name,
                        "value": colorItem.value
                    });
                }

                return {
                    "family": fam,
                    "variant": obj.variant,
                    "displayName": obj.getDisplayName(),
                    "emoji": obj.emoji,
                    "colors": safeColors,
                    "previewColors": safePreviewColors,
                    "isDark": obj.isDark
                }
            });
            
            tempGroups.push({
                "family": fam,
                "variants": variantsArray
            });
        }
        
        groupedModel = tempGroups;

        Qt.callLater(function() {
            if (!contentReady)
                contentReady = true
        })
    }

    Connections {
        target: Svc.ThemeModel
        function onLoaded() {
            rebuildGroupedModel(); 
        }
    }
    
    Component.onCompleted: {
        if (groupedModel.count > 0) {
            contentReady = true
        }
    }
    
    // --- Main Layout ---
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true
        
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        
        flickDeceleration: 1500
        maximumFlickVelocity: 2500
        
        ScrollBar.vertical: ScrollBar { 
            policy: ScrollBar.AsNeeded
            
            // ✨ Smooth show/hide
            opacity: flickable.moving || flickable.dragging ? 1.0 : 0.3
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
        
        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 20
            
            // ✨ Overall entrance fade
            opacity: root.contentReady ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
            
            // --- Current theme indicator with animation ---
            Rectangle {
                Layout.fillWidth: true
                height: 60
                radius: 12
                color: Th.Theme.primary
                
                // ✨ IMPROVED: Slide from top
                transform: Translate {
                    y: root.contentReady ? 0 : -30
                    Behavior on y {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                }
                
                // ✨ Subtle pulse on theme change
                property bool themeChanged: false
                
                Connections {
                    target: Cfg.Theme
                    function onPaletteFamilyChanged() { parent.themeChanged = true }
                    function onPaletteVariantChanged() { parent.themeChanged = true }
                }
                
                scale: themeChanged ? 1.05 : 1.0
                Behavior on scale {
                    SequentialAnimation {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                        ScriptAction {
                            script: parent.themeChanged = false
                        }
                    }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    Text {
                        text: "🎨"
                        font.pixelSize: 24
                        
                        // ✨ Rotate on theme change
                        rotation: parent.parent.themeChanged ? 360 : 0
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Current Theme"
                            color: Th.Theme.bg
                            font.pixelSize: 12
                            opacity: 0.8
                        }
                        
                        Text {
                            text: Cfg.Theme.paletteFamily + " " + Cfg.Theme.paletteVariant
                            color: Th.Theme.bg
                            font.pixelSize: 16
                            font.bold: true
                            
                            // ✨ Smooth color transition
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }
            }
            
            // --- Theme families with staggered entrance ---
            Repeater {
                model: root.groupedModel
                
                delegate: ColumnLayout {
                    id: familyDelegate
                    Layout.fillWidth: true
                    spacing: 12
                    
                    required property var modelData
                    required property int index
                    
                    // ✨ IMPROVED: Staggered slide-in per family
                    opacity: root.contentReady ? 1 : 0
                    transform: Translate {
                        x: root.contentReady ? 0 : -20
                    }
                    
                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: Math.min(familyDelegate.index * 100, 400)
                            }
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    Behavior on x {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    // Family header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Text {
                            text: familyDelegate.modelData.family.toUpperCase()
                            color: Th.Theme.secondary
                            font.pixelSize: 13
                            font.letterSpacing: 2
                            font.weight: Font.Bold
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
                            
                            // ✨ Width animation
                            width: root.contentReady ? parent.width : 0
                            Behavior on width {
                                NumberAnimation {
                                    duration: 600
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                    
                    // Variant grid
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Repeater {
                            model: familyDelegate.modelData.variants
                            
                            delegate: ThemeChip {
                                required property var modelData
                                required property int index

                                family: familyDelegate.modelData.family
                                variant: modelData.variant
                                themeData: modelData
                                isActive: Cfg.Theme.paletteFamily === family && 
                                         Cfg.Theme.paletteVariant === variant
                                onActivate: Th.Theme.setPalette(family, variant)
                                
                                // ✨ IMPROVED: Staggered appearance
                                opacity: root.contentReady ? 1 : 0
                                scale: root.contentReady ? 1 : 0.8
                                
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 400
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 450
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.2
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // --- Enhanced Theme Chip Component ---
    component ThemeChip: Rectangle {
        id: chip
        
        property string family
        property string variant
        property var themeData 
        property bool isActive: false

        signal activate()

        width: 240
        height: 50
        radius: 8
        
        color: isActive ? Qt.rgba(Th.Theme.primary.r, Th.Theme.primary.g, Th.Theme.primary.b, 0.1) : "transparent"
        border.width: isActive ? 2 : 1
        border.color: isActive ? Th.Theme.primary : Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.15)

        // ✨ IMPROVED: Smooth border transitions
        Behavior on border.color {
            ColorAnimation { duration: 250 }
        }
        Behavior on border.width {
            NumberAnimation { duration: 200 }
        }
        Behavior on color {
            ColorAnimation { duration: 250 }
        }
        
        // ✨ IMPROVED: Hover and active scale
        scale: clickArea.pressed ? 0.95 : (clickArea.containsMouse || isActive ? 1.02 : 1.0)
        Behavior on scale {
            SpringAnimation {
                spring: 3.5
                damping: 0.4
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0
            
            // Left Section: Info & Activation
            MouseArea {
                id: clickArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: chip.activate()
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    // ✨ IMPROVED: Active indicator with animation
                    Rectangle {
                        width: 4
                        height: chip.isActive ? 16 : 0
                        radius: 2
                        color: Th.Theme.primary
                        
                        Behavior on height {
                            SpringAnimation {
                                spring: 3
                                damping: 0.5
                            }
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        // Variant Name
                        Text {
                            text: chip.variant.replace("_", " ")
                            color: Th.Theme.fg
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            
                            // ✨ Smooth color transition
                            Behavior on color {
                                ColorAnimation { duration: 250 }
                            }
                        }
                        
                        // ✨ IMPROVED: Color Preview with pop-in animation
                        Row {
                            spacing: 4
                            Repeater {
                                model: chip.themeData.previewColors
                                delegate: Rectangle {
                                    required property color modelData
                                    required property int index
                                    
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: modelData
                                    border.width: 1
                                    border.color: Qt.rgba(0,0,0,0.1)
                                    
                                    // ✨ Staggered pop-in
                                    scale: root.contentReady ? 1 : 0
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutBack
                                            easing.overshoot: 1.5
                                        }
                                    }
                                    
                                    // ✨ Hover grow effect
                                    property bool hovered: colorHover.containsMouse
                                    
                                    MouseArea {
                                        id: colorHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                    
                                    transform: Scale {
                                        origin.x: width / 2
                                        origin.y: height / 2
                                        xScale: parent.hovered ? 1.3 : 1.0
                                        yScale: parent.hovered ? 1.3 : 1.0
                                        
                                        Behavior on xScale {
                                            SpringAnimation {
                                                spring: 4
                                                damping: 0.3
                                            }
                                        }
                                        Behavior on yScale {
                                            SpringAnimation {
                                                spring: 4
                                                damping: 0.3
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.margins: 4
                color: chip.border.color
                
                Behavior on color {
                    ColorAnimation { duration: 250 }
                }
            }
            
            // ✨ IMPROVED: Details Button with hover animation
            Rectangle {
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                color: detailsArea.containsMouse
                       ? Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
                       : "transparent"
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                
                // ✨ Scale on hover
                scale: detailsArea.pressed ? 0.9 : (detailsArea.containsMouse ? 1.1 : 1.0)
                Behavior on scale {
                    SpringAnimation {
                        spring: 4
                        damping: 0.3
                    }
                }
                
                Text {
                    text: "⋮" 
                    color: Th.Theme.secondary
                    font.pixelSize: 18
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    id: detailsArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: detailsPopup.open()
                }
            }
        }
        
        // --- Enhanced Details Popup ---
        Popup {
            id: detailsPopup
            implicitWidth: 320
            implicitHeight: 400
            padding: 0
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            anchors.centerIn: Overlay.overlay
            
            // ✨ IMPROVED: Smooth entrance animation
            enter: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 0.85
                        to: 1.0
                        duration: 300
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.3
                    }
                }
            }
            
            exit: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 200
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 1.0
                        to: 0.9
                        duration: 200
                        easing.type: Easing.InCubic
                    }
                }
            }
            
            background: Rectangle {
                color: Th.Theme.bg
                border.color: Th.Theme.primary
                border.width: 2
                radius: 12
                
                // ✨ Enhanced shadow
                Rectangle {
                    z: -1
                    anchors.fill: parent
                    anchors.margins: -6
                    color: Qt.rgba(0,0,0,0.3)
                    radius: 16
                }
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                
                // Popup Header
                Text {
                    text: chip.family + " " + chip.variant
                    font.pixelSize: 18
                    font.bold: true
                    color: Th.Theme.fg
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Rectangle { 
                    Layout.fillWidth: true
                    height: 1
                    color: Th.Theme.surface
                }
                
                // Colors List with staggered entrance
                ListView {
                    id: colorListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: chip.themeData.colors
                    spacing: 8
                    
                    // ✨ Smooth scrolling
                    flickDeceleration: 1500
                    
                    delegate: RowLayout {
                        width: ListView.view.width
                        spacing: 10
                        
                        required property var modelData
                        required property int index
                        
                        // ✨ Staggered entrance
                        opacity: detailsPopup.opened ? 1 : 0
                        transform: Translate {
                            x: detailsPopup.opened ? 0 : -20
                        }
                        
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on x {
                            NumberAnimation {
                                duration: 350
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        // ✨ IMPROVED: Color Circle with hover scale
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: modelData.value
                            border.width: 1
                            border.color: Qt.rgba(1,1,1,0.1)
                            
                            scale: colorCircleHover.containsMouse ? 1.2 : 1.0
                            Behavior on scale {
                                SpringAnimation {
                                    spring: 4
                                    damping: 0.3
                                }
                            }
                            
                            MouseArea {
                                id: colorCircleHover
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                        
                        // Name
                        Text {
                            text: modelData.name
                            color: Th.Theme.fg
                            font.pixelSize: 14
                            Layout.fillWidth: true
                        }
                        
                        // Hex Input Group
                        HexCopyField {
                            colorValue: modelData.value
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        opacity: colorListView.moving ? 1.0 : 0.5
                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }
            }
        }
    }
    
    // --- Enhanced Hex Copy Field ---
    component HexCopyField: Rectangle {
        id: fieldRoot
        property color colorValue
        
        Layout.preferredWidth: 110
        Layout.preferredHeight: 30
        
        color: Th.Theme.surface
        radius: 6
        border.width: 1
        border.color: Qt.rgba(Th.Theme.fg.r, Th.Theme.fg.g, Th.Theme.fg.b, 0.1)
        
        // ✨ Hover effect
        scale: fieldHover.containsMouse ? 1.03 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        
        property alias containsMouse: fieldHover.containsMouse
        
        MouseArea {
            id: fieldHover
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
        }
        
        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            // Hex Text
            TextField {
                id: hexInput
                text: fieldRoot.colorValue.toString()
                readOnly: true
                color: Th.Theme.fg
                
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                background: Item {}
                font.pixelSize: 12
                font.family: "Monospace"
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
            }
            
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: fieldRoot.border.color
            }
            
            // ✨ IMPROVED: Animated Copy Button
            Button {
                id: copyBtn
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                flat: true
                
                contentItem: Text {
                    text: copyBtn.copied ? "✓" : "❐"
                    color: copyBtn.copied ? Th.Theme.success : Th.Theme.secondary
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    // ✨ Smooth color transition
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    
                    // ✨ Pop animation on copy
                    scale: copyBtn.copied ? 1.2 : 1.0
                    Behavior on scale {
                        SequentialAnimation {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                            PauseAnimation { duration: 1000 }
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
                
                property bool copied: false
                
                background: Rectangle {
                    color: copyBtn.hovered ? Qt.rgba(1,1,1,0.1) : "transparent"
                    radius: 4
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                onClicked: {
                    hexInput.selectAll()
                    hexInput.copy()
                    hexInput.deselect()
                    
                    copied = true
                    timer.restart()
                }
                
                Timer {
                    id: timer
                    interval: 1500
                    onTriggered: copyBtn.copied = false
                }
            }
        }
    }
}
