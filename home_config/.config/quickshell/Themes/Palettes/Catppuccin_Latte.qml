pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePaletteModel {
    id: root
    family: "Catppuccin"
    variant: "Latte"
    emoji: "🌻"
    previewColors: [ fg, bg, primary, secondary, accent, surface, error, warning, success, info ]
    colors: [
        Models.ColorModel { name: "rosewater"; value: root.rosewater },
        Models.ColorModel { name: "flamingo"; value: root.flamingo },
        Models.ColorModel { name: "pink"; value: root.pink },
        Models.ColorModel { name: "mauve"; value: root.mauve },
        Models.ColorModel { name: "red"; value: root.red },
        Models.ColorModel { name: "maroon"; value: root.maroon },
        Models.ColorModel { name: "peach"; value: root.peach },
        Models.ColorModel { name: "yellow"; value: root.yellow },
        Models.ColorModel { name: "green"; value: root.green },
        Models.ColorModel { name: "teal"; value: root.teal },
        Models.ColorModel { name: "sky"; value: root.sky },
        Models.ColorModel { name: "sapphire"; value: root.sapphire },
        Models.ColorModel { name: "blue"; value: root.blue },
        Models.ColorModel { name: "lavender"; value: root.lavender },
        Models.ColorModel { name: "text"; value: root.text },
        Models.ColorModel { name: "subtext1"; value: root.subtext1 },
        Models.ColorModel { name: "subtext0"; value: root.subtext0 },
        Models.ColorModel { name: "overlay2"; value: root.overlay2 },
        Models.ColorModel { name: "overlay1"; value: root.overlay1 },
        Models.ColorModel { name: "overlay0"; value: root.overlay0 },
        Models.ColorModel { name: "surface2"; value: root.surface2 },
        Models.ColorModel { name: "surface1"; value: root.surface1 },
        Models.ColorModel { name: "surface0"; value: root.surface0 },
        Models.ColorModel { name: "base"; value: root.base },
        Models.ColorModel { name: "mantle"; value: root.mantle },
        Models.ColorModel { name: "crust"; value: root.crust }
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
