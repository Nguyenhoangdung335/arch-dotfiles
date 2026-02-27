pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // readonly property string cacheDir: `${Quickshell.env("XDG_CACHE_HOME", Quickshell.env("HOME") + "/.cache")}/quickshell/wallpapers`
    readonly property string cacheDir: {
        // var xdgCache = Quickshell.env("XDG_CACHE_HOME", Quickshell.env("HOME") + "/.cache");
        var cachePath = Quickshell.env("XDG_CACHE_HOME");
        if (!cachePath) {
            cachePath = Quickshell.env("HOME") + "/.cache";
        }
        return cachePath + "/quickshell/wallpapers";
    }

    ListModel { id: internalModel }

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
}
