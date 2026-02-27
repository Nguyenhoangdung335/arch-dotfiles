pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    readonly property string defaultFamily: "Catppuccin"
    readonly property string defaultVariant: "Mocha"
    readonly property string defaultWallpaperDir: `${Quickshell.env("HOME")}/Pictures/Wallpapers`
    
    // Configuration properties (bound to JSON adapter)
    property string paletteFamily: defaultFamily
    property string paletteVariant: defaultVariant
    property string wallpaperDir: defaultWallpaperDir
    
    readonly property string configPath: `${Quickshell.env("HOME")}/.config/quickshell/theme.json`
    
    // FileView with JsonAdapter for automatic persistence
    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        printErrors: Global.isDebug

        onAdapterUpdated: writeAdapter()
        
        JsonAdapter {
            id: adapter
            
            // Bind config properties to JSON fields
            property string paletteFamily: root.paletteFamily
            property string paletteVariant: root.paletteVariant
            property string wallpaperDir: root.wallpaperDir
            
            // Load from file on startup
            onPaletteFamilyChanged: if (paletteFamily) root.paletteFamily = paletteFamily
            onPaletteVariantChanged: if (paletteVariant) root.paletteVariant = paletteVariant
            onWallpaperDirChanged: if (wallpaperDir) root.wallpaperDir = wallpaperDir
        }


        onLoadFailed: (err) => {
            if (err === FileViewError.FileNotFound) {
                // File doesn't exist - create with defaults
                console.log("Theme config file not found, creating default at " + root.configPath);
                adapter.paletteFamily = root.defaultFamily;
                adapter.paletteVariant = root.defaultVariant;
                adapter.wallpaperDir = root.defaultWallpaperDir;
                writeAdapter();
            }
            // console.error("Failed to load theme config:", err, err.toString(), FileViewError.toString(err));
        }
    }
    
    // Automatically save when properties change
    onPaletteFamilyChanged: Qt.callLater(() => adapter.paletteFamily = paletteFamily)
    onPaletteVariantChanged: Qt.callLater(() => adapter.paletteVariant = paletteVariant)
    onWallpaperDirChanged: Qt.callLater(() => adapter.wallpaperDir = wallpaperDir)
}
