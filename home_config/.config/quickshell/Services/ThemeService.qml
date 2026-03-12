// ./Services/ThemeService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "../Config" as Cfg
import "../Themes" as Th
import "../Models" as Models

Singleton {
    id: root

    // Public model property
    property alias dataName: internalModel
    property var dataMap: {}
    property var groupedThemes: []
    property int count: internalModel.count
    
    // Path to palettes directory
    readonly property string palettesPath: Cfg.Global.rootPath + "/Themes/Palettes"

    signal loaded()

    ListModel { id: internalModel }

    // Use Process to list directory since FileView doesn't support directory listing
    Process {
        id: paletteScanner
        running: true
        command: ["ls", "-1", root.palettesPath]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (Cfg.Global.isDebug) console.log("ThemeService: Scanned directory", root.palettesPath);
                if (this.text.trim().length > 0) root.parseEntries(this.text);
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.error("ThemeService: Error scanning palettes directory", data);
            }
        }
    }
    
    function parseEntries(data: string) {
        let tempMap = {};
        let tempModelList = [];
        let familyMap = {};
        
        const lines = data.trim().split("\n");
        
        for (const fileName of lines) {
            if (!fileName || !fileName.endsWith(".qml") || fileName === "qmldir") continue;
            
            const nameWithoutExt = fileName.replace(".qml", "");
            const parts = nameWithoutExt.split("_");
            
            if (parts.length >= 2) {
                const family = parts[0];
                const variant = parts.slice(1).join("_");
                const palette = Th.Theme.getPalette(family, variant);
                
                if (palette) {
                    const displayName = palette.getDisplayName();
                    
                    // Add to temp array
                    tempModelList.push({ displayName: displayName });
                    
                    // Add to temp map
                    tempMap[displayName] = palette;

                    // Add to family map
                    if (!familyMap[family]) {
                        familyMap[family] = [];
                    }

                    // Pre-convert QML lists to standard JS arrays for easy UI binding
                    var safePreviewColors = [];
                    for (var p = 0; p < palette.previewColors.length; p++) {
                        safePreviewColors.push(palette.previewColors[p]);
                    }

                    var safeColors = [];
                    for (var c = 0; c < palette.colors.length; c++) {
                        var colorItem = palette.colors[c];
                        safeColors.push({
                            "name": colorItem.name,
                            "value": colorItem.value
                        });
                    }

                    familyMap[family].push({
                        "family": family,
                        "variant": variant,
                        "displayName": displayName,
                        "emoji": palette.emoji,
                        "colors": safeColors,
                        "previewColors": safePreviewColors,
                        "isDark": palette.isDark
                    });
                }
            }
        }

        let tempGroups = [];
        for (let fam in familyMap) {
            tempGroups.push({
                "family": fam,
                "variants": familyMap[fam]
            });
        }

        dataMap = tempMap; 
        groupedThemes = tempGroups;
        
        internalModel.clear();
        for (const item of tempModelList) {
            internalModel.append(item);
        }
        loaded();
        if (Cfg.Global.isDebug) {
            console.log("ThemeService: Loaded", tempModelList.length, "themes");
        }
    }

    // For forcing initial load on startup
    function load () {}
}
