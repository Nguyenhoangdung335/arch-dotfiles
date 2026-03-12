import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../Themes" as Th
import "../../Config" as Cfg
import "../../Services" as Svc
import "../../Components" as Comp

// Theme palette selection tab with smooth animations
Item {
    id: root
    
    // ✨ Animation state
    property bool contentReady: false
    
    Connections {
        target: Svc.ThemeService
        function onLoaded() {
            Qt.callLater(function() {
                if (!root.contentReady)
                    root.contentReady = true
            });
        }
    }
    
    Component.onCompleted: {
        if (Svc.ThemeService.groupedThemes && Svc.ThemeService.groupedThemes.length > 0) {
            contentReady = true;
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
                id: currentThemeRect // 5. Added ID to fix themeChanged binding
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
                    // 5. Use explicit ID instead of parent
                    function onPaletteFamilyChanged() { currentThemeRect.themeChanged = true }
                    function onPaletteVariantChanged() { currentThemeRect.themeChanged = true }
                }
                
                scale: themeChanged ? 1.05 : 1.0
                Behavior on scale {
                    SequentialAnimation {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                        ScriptAction {
                            script: currentThemeRect.themeChanged = false
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
                        rotation: currentThemeRect.themeChanged ? 360 : 0
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
                model: Svc.ThemeService.groupedThemes
                
                delegate: ColumnLayout {
                    id: familyDelegate
                    Layout.fillWidth: true
                    spacing: 12
                    
                    required property var modelData
                    required property int index
                    
                    // REVERTED to original Staggered slide-in per family
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
                            
                            delegate: Comp.ThemeChip {
                                required property var modelData
                                required property int index

                                family: familyDelegate.modelData.family
                                variant: modelData.variant
                                themeData: modelData
                                contentReady: root.contentReady
                                isActive: Cfg.Theme.paletteFamily === family && 
                                         Cfg.Theme.paletteVariant === variant
                                onActivate: Th.Theme.setPalette(family, variant)
                                
                                // REVERTED to original Staggered appearance
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
}
