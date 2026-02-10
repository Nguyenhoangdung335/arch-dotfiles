pragma Singleton

import QtQuick

import "../../Models" as Models

Models.ThemePalette {
    id: root
    family: "Catppuccin"
    variant: "Macchiato"
    emoji: "🌺"
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
    readonly property color rosewater: "#f4dbd6"
    readonly property color flamingo: "#f0c6c6"
    readonly property color pink: "#f5bde6"
    readonly property color mauve: "#c6a0f6"
    readonly property color red: "#ed8796"
    readonly property color maroon: "#ee99a0"
    readonly property color peach: "#f5a97f"
    readonly property color yellow: "#eed49f"
    readonly property color green: "#a6da95"
    readonly property color teal: "#8bd5ca"
    readonly property color sky: "#91d7e3"
    readonly property color sapphire: "#7dc4e4"
    readonly property color blue: "#8aadf4"
    readonly property color lavender: "#b7bdf8"

    // Surface Colors
    readonly property color text: "#cad3f5"
    readonly property color subtext1: "#b8c0e0"
    readonly property color subtext0: "#a5adcb"
    readonly property color overlay2: "#939ab7"
    readonly property color overlay1: "#8087a2"
    readonly property color overlay0: "#6e738d"
    readonly property color surface2: "#5b6078"
    readonly property color surface1: "#494d64"
    readonly property color surface0: "#363a4f"
    readonly property color base: "#24273a"
    readonly property color mantle: "#1e2030"
    readonly property color crust: "#181926"
}
