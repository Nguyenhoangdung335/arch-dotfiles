pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePaletteModel {
    // Metadata
    id: root
    family: "Catppuccin"
    variant: "Frappe"
    emoji: "🪴"
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
    isDark: true

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
    readonly property color rosewater: "#f2d5cf"
    readonly property color flamingo: "#eebebe"
    readonly property color pink: "#f4b8e4"
    readonly property color mauve: "#ca9ee6"
    readonly property color red: "#e78284"
    readonly property color maroon: "#ea999c"
    readonly property color peach: "#ef9f76"
    readonly property color yellow: "#e5c890"
    readonly property color green: "#a6d189"
    readonly property color teal: "#81c8be"
    readonly property color sky: "#99d1db"
    readonly property color sapphire: "#85c1dc"
    readonly property color blue: "#8caaee"
    readonly property color lavender: "#babbf1"

    // Surface Colors
    readonly property color text: "#c6d0f5"
    readonly property color subtext1: "#b5bfe2"
    readonly property color subtext0: "#a5adce"
    readonly property color overlay2: "#949cbb"
    readonly property color overlay1: "#838ba7"
    readonly property color overlay0: "#737994"
    readonly property color surface2: "#626880"
    readonly property color surface1: "#51576d"
    readonly property color surface0: "#414559"
    readonly property color base: "#303446"
    readonly property color mantle: "#292c3c"
    readonly property color crust: "#232634"
}
