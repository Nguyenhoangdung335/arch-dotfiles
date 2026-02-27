pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePalette {
    id: root
    family: "Catppuccin"
    variant: "Latte"
    emoji: "🌻"
    previewColors: [ fg, bg, primary, secondary, accent, surface, error, warning, success, info ]
    colors: [
        Models.ColorName { name: "rosewater"; value: root.rosewater },
        Models.ColorName { name: "flamingo"; value: root.flamingo },
        Models.ColorName { name: "pink"; value: root.pink },
        Models.ColorName { name: "mauve"; value: root.mauve },
        Models.ColorName { name: "red"; value: root.red },
        Models.ColorName { name: "maroon"; value: root.maroon },
        Models.ColorName { name: "peach"; value: root.peach },
        Models.ColorName { name: "yellow"; value: root.yellow },
        Models.ColorName { name: "green"; value: root.green },
        Models.ColorName { name: "teal"; value: root.teal },
        Models.ColorName { name: "sky"; value: root.sky },
        Models.ColorName { name: "sapphire"; value: root.sapphire },
        Models.ColorName { name: "blue"; value: root.blue },
        Models.ColorName { name: "lavender"; value: root.lavender },
        Models.ColorName { name: "text"; value: root.text },
        Models.ColorName { name: "subtext1"; value: root.subtext1 },
        Models.ColorName { name: "subtext0"; value: root.subtext0 },
        Models.ColorName { name: "overlay2"; value: root.overlay2 },
        Models.ColorName { name: "overlay1"; value: root.overlay1 },
        Models.ColorName { name: "overlay0"; value: root.overlay0 },
        Models.ColorName { name: "surface2"; value: root.surface2 },
        Models.ColorName { name: "surface1"; value: root.surface1 },
        Models.ColorName { name: "surface0"; value: root.surface0 },
        Models.ColorName { name: "base"; value: root.base },
        Models.ColorName { name: "mantle"; value: root.mantle },
        Models.ColorName { name: "crust"; value: root.crust }
    ]
    isDark: false
    // Standard Interface
    bg: base
    fg: text
    primary: blue
    secondary: mauve
    accent: lavender
    surface: surface0
    error: red
    warning: yellow
    success: green
    info: sky

    // Base Colors
    readonly property color rosewater: "#dc8a78"
    readonly property color flamingo: "#dd7878"
    readonly property color pink: "#ea76cb"
    readonly property color mauve: "#8839ef"
    readonly property color red: "#d20f39"
    readonly property color maroon: "#e64553"
    readonly property color peach: "#fe640b"
    readonly property color yellow: "#df8e1d"
    readonly property color green: "#40a02b"
    readonly property color teal: "#179299"
    readonly property color sky: "#04a5e5"
    readonly property color sapphire: "#209fb5"
    readonly property color blue: "#1e66f5"
    readonly property color lavender: "#7287fd"

    // Surface Colors
    readonly property color text: "#4c4f69"
    readonly property color subtext1: "#5c5f77"
    readonly property color subtext0: "#6c6f85"
    readonly property color overlay2: "#7c7f93"
    readonly property color overlay1: "#8c8fa1"
    readonly property color overlay0: "#9ca0b0"
    readonly property color surface2: "#acb0be"
    readonly property color surface1: "#bcc0cc"
    readonly property color surface0: "#ccd0da"
    readonly property color base: "#eff1f5"
    readonly property color mantle: "#e6e9ef"
    readonly property color crust: "#dce0e8"
}
