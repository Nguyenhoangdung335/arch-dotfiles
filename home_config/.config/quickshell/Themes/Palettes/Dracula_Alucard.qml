pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePaletteModel {
    id: root
    family: "Dracula"
    variant: "Alucard"
    emoji: "⚔️"
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

    // Color Palette (Light variant)
    readonly property color background: "#fffbeb"
    readonly property color currentLine: "#6c664b"
    readonly property color selection: "#cfcfde"
    readonly property color foreground: "#1f1f1f"
    readonly property color comment: "#6c664b"
    readonly property color cyan: "#036a96"
    readonly property color green: "#14710a"
    readonly property color orange: "#a34d14"
    readonly property color pink: "#a3144d"
    readonly property color purple: "#644ac9"
    readonly property color red: "#cb3a2a"
    readonly property color yellow: "#846e15"
}
