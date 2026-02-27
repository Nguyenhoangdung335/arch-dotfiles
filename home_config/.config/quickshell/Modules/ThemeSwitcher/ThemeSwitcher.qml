import QtQuick

import "../../Components"
import "../../Themes" as Th
import "../../Config" as Cfg
import "../../Services" as Svc

Rectangle {
    id: root
    
    implicitWidth: contentLayout.implicitWidth + 40
    implicitHeight: contentLayout.implicitHeight + 40
    
    // --- Glassmorphism Container ---
    color: Th.Theme.bg
    opacity: 0.75
    radius: 24
    border.color: Th.Theme.fg
    border.width: 1
    
    // --- Drop Shadow (Elevation) ---
    Rectangle {
        anchors.fill: parent
        anchors.margins: -10
        z: -1
        radius: root.radius
        color: "#000000"
        opacity: 0.3
    }

    // --- Layout ---
    Column {
        id: contentLayout
        anchors.centerIn: parent
        width: 420
        spacing: 20
        padding: 24

        Text {
            text: "Theme Selector"
            color: Th.Theme.fg
            font.pixelSize: 22
            font.bold: true
        }

        // --- Palette Scanner Service ---
        Svc.ThemeModel {
            id: themeService
            onCountChanged: rebuildGroupedModel()
        }

        function rebuildGroupedModel() {
            themesModel.clear();
            var familyMap = {};
            
            for (var i = 0; i < themeService.count; i++) {
                var item = themeService.model.get(i);
                var family = item.family;
                var variant = item.variant;
                
                if (!familyMap[family]) {
                    familyMap[family] = [];
                }
                familyMap[family].push(variant);
            }
            
            // Convert map to list model
            for (var fam in familyMap) {
                themesModel.append({
                    "family": fam,
                    "variants": familyMap[fam]
                });
            }
        }

        // Build a map of families to variants
        ListModel {
            id: themesModel
            Component.onCompleted: root.rebuildGroupedModel()
        }

        // Display themes grouped by family
        Repeater {
            model: themesModel
            
            delegate: Column {
                width: parent.width
                spacing: 12

                // Family Header
                Text {
                    text: model.family.toUpperCase()
                    color: Th.Theme.secondary
                    font.pixelSize: 13
                    font.letterSpacing: 1.5
                    font.bold: true
                }

                Flow {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: variants
                        
                        delegate: VariantChip {
                            // Display variant name
                            label: modelData
                            
                            // Check if this is currently selected
                            isActive: Cfg.Theme.paletteFamily === family && 
                                      Cfg.Theme.paletteVariant === modelData
                                      
                            onClicked: {
                                Th.Theme.setPalette(family, modelData);
                            }
                            
                            // --- Style Binding ---
                            color: isActive ? Th.Theme.primary : "transparent"
                            border.color: Th.Theme.fg
                            
                            contentText.color: isActive 
                                               ? Th.Theme.bg 
                                               : Th.Theme.fg
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Th.Theme.fg
                    opacity: 0.1
                }
            }
        }
    }
}
