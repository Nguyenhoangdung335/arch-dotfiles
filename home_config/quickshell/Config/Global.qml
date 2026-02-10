pragma Singleton

import Quickshell

Singleton {
    id: root
    
    property bool isDebug: true
    
    // Root path of the quickshell configuration
    // Automatically detected from shell.qml location
    readonly property string rootPath: {
        const shellPath = Quickshell.shellDir;
        if (isDebug) {
            console.log("Global: rootPath detected as", shellPath);
        }
        return shellPath;
    }

    function toggleDebug() {
        isDebug = !isDebug;
    }

    // Helper to resolve paths relative to rootPath
    function resolvePath(...parts): string {
        const clean = parts
            .filter(p => p && p.length > 0)
            .map(p => p.replace(/^\/+|\/+$/g, ""));
        return Qt.resolvedUrl(rootPath + "/" + clean.join("/"));
    }
}
