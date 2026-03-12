pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePaletteModel {
    id: root
    family: "Dracula"
    variant: "Dracula"
    emoji: "🧛"
    previewColors: [ fg, bg, primary, secondary, accent, surface, error, warning, success, info ]
    colors: [
        Models.ColorModel { name: "background"; value: root.background },
        Models.ColorModel { name: "currentLine"; value: root.currentLine },
        Models.ColorModel { name: "selection"; value: root.selection },
        Models.ColorModel { name: "foreground"; value: root.foreground },
        Models.ColorModel { name: "comment"; value: root.comment },
        Models.ColorModel { name: "cyan"; value: root.cyan },
        Models.ColorModel { name: "green"; value: root.green },
        Models.ColorModel { name: "orange"; value: root.orange },
        Models.ColorModel { name: "pink"; value: root.pink },
        Models.ColorModel { name: "purple"; value: root.purple },
        Models.ColorModel { name: "red"; value: root.red },
        Models.ColorModel { name: "yellow"; value: root.yellow }
    ]
    isDark: false

    bg: background
    fg: foreground
    primary: purple
    secondary: cyan
    accent: orange
    surface: currentLine
    error: red
    warning: yellow
    success: green
    info: cyan

    // Color Palette
    readonly property color background: "#282a36"
    readonly property color currentLine: "#44475a"
    readonly property color selection: "#44475a"
    readonly property color foreground: "#f8f8f2"
    readonly property color comment: "#6272a4"
    readonly property color cyan: "#8be9fd"
    readonly property color green: "#50fa7b"
    readonly property color orange: "#ffb86c"
    readonly property color pink: "#ff79c6"
    readonly property color purple: "#bd93f9"
    readonly property color red: "#ff5555"
    readonly property color yellow: "#f1fa8c"
}

