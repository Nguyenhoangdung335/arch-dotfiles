pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePalette {
    id: root
    family: "Dracula"
    variant: "Alucard"
    emoji: "⚔️"
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
