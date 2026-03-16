// ./Themes/Palettes/Catppuccin_Mocha.qml
pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePaletteModel {
    id: root
    family: "Catppuccin"
    variant: "Mocha"
    emoji: "🌿"
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
    readonly property color rosewater: "#f5e0dc"
    readonly property color flamingo: "#f2cdcd"
    readonly property color pink: "#f5c2e7"
    readonly property color mauve: "#cba6f7"
    readonly property color red: "#f38ba8"
    readonly property color maroon: "#eba0ac"
    readonly property color peach: "#fab387"
    readonly property color yellow: "#f9e2af"
    readonly property color green: "#a6e3a1"
    readonly property color teal: "#94e2d5"
    readonly property color sky: "#89dceb"
    readonly property color sapphire: "#74c7ec"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"

    // Surface Colors
    readonly property color text: "#cdd6f4"
    readonly property color subtext1: "#bac2de"
    readonly property color subtext0: "#a6adc8"
    readonly property color overlay2: "#9399b2"
    readonly property color overlay1: "#7f849c"
    readonly property color overlay0: "#6c7086"
    readonly property color surface2: "#585b70"
    readonly property color surface1: "#45475a"
    readonly property color surface0: "#313244"
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
}
