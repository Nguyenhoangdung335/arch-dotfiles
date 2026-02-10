// ./Services/ThemeModel.qml
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
                if (Cfg.Global.isDebug) console.log("ThemeModel: Scanned directory", root.palettesPath);
                if (this.text.trim().length > 0) root.parseEntries(this.text);
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.error("ThemeModel: Error scanning palettes directory", data);
            }
        }
    }
    
    function parseEntries(data: string) {
        let tempMap = {};
        let tempModelList = [];
        
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
                }
            }
        }

        dataMap = tempMap; 
        internalModel.clear();
        for (const item of tempModelList) {
            internalModel.append(item);
        }
        loaded();
        if (Cfg.Global.isDebug) {
            console.log("ThemeModel: Loaded", tempModelList.length, "themes");
        }
    }

    // For forcing initial load on startup
    function load () {}
}
