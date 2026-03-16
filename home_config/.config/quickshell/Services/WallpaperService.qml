pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import "../Config" as Cfg

Singleton {
    id: root

    readonly property string cacheDir: {
        var cachePath = Quickshell.env("XDG_CACHE_HOME");
        if (!cachePath) {
            cachePath = Quickshell.env("HOME") + "/.cache";
        }
        return cachePath + "/quickshell/wallpapers";
    }

    // Public properties
    property alias wallpapers: internalModel
    property bool isReady: false
    property bool isGenerating: false

    ListModel { id: internalModel }

    // Utility functions for paths
    function getThumbnailPath(wallpaperPath: string): string {
        var fileName = wallpaperPath.split('/').pop()
        var baseName = fileName.substring(0, fileName.lastIndexOf('.')) || fileName
        var dirName = wallpaperPath.split('/').slice(0, -1).join('/').split('/').pop()
        return root.cacheDir + "/" + dirName + "/" + baseName + ".jpg"
    }

    function getThumbnailsDir(wallpaperDir: string): string {
        var dirName = wallpaperDir.split('/').pop()
        return root.cacheDir + "/" + dirName
    }

    // Process to generate thumbnails
    Process {
        id: thumbnailGen
        running: false
        command: [Quickshell.shellDir + "/Scripts/generate-thumbnails.sh", Cfg.Theme.wallpaperDir]
        
        onExited: function(exitCode, exitStatus) {
            root.isGenerating = false;
            // Now that thumbnails are guaranteed to be generated, scan the directory
            wallpaperScanner.running = true;
        }
    }

    // Process to scan wallpapers
    Process {
        id: wallpaperScanner
        running: false
        command: ["ls", "-1", Cfg.Theme.wallpaperDir]

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) root.parseWallpapers(this.text);
            }
        }
    }

    function parseWallpapers(data: string) {
        const lines = data.trim().split("\n");
        let tempModelList = [];

        for (const fileName of lines) {
            if (!fileName) continue;

            const ext = fileName.split('.').pop().toLowerCase();

            if (Cfg.Theme.imageExtensions.includes(ext)) {
                var fullPath = Cfg.Theme.wallpaperDir + "/" + fileName;
                var thumbPath = root.getThumbnailPath(fullPath);
                
                tempModelList.push({
                    name: fileName,
                    path: fullPath,
                    thumbnailPath: thumbPath
                });
            }
        }

        internalModel.clear();
        for (const item of tempModelList) {
            internalModel.append(item);
        }
        
        root.isReady = true;
    }

    // Public API to trigger a scan manually
    function rescan() {
        root.isReady = false;
        root.isGenerating = true;
        thumbnailGen.running = true;
    }

    // Auto-rescan when wallpaper dir changes
    Connections {
        target: Cfg.Theme
        function onWallpaperDirChanged() {
            root.rescan();
        }
    }

    // Initial load
    Component.onCompleted: {
        root.rescan();
    }
}
