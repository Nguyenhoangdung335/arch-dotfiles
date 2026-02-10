pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePalette {
    id: root
    family: "Dracula"
    variant: "Dracula"
    emoji: "🧛"
    previewColors: [ fg, bg, primary, secondary, accent, surface, error, warning, success, info ]
    colors: [
        Models.ColorName { name: "background"; value: root.background },
        Models.ColorName { name: "currentLine"; value: root.currentLine },
        Models.ColorName { name: "selection"; value: root.selection },
        Models.ColorName { name: "foreground"; value: root.foreground },
        Models.ColorName { name: "comment"; value: root.comment },
        Models.ColorName { name: "cyan"; value: root.cyan },
        Models.ColorName { name: "green"; value: root.green },
        Models.ColorName { name: "orange"; value: root.orange },
        Models.ColorName { name: "pink"; value: root.pink },
        Models.ColorName { name: "purple"; value: root.purple },
        Models.ColorName { name: "red"; value: root.red },
        Models.ColorName { name: "yellow"; value: root.yellow }
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

