pragma Singleton

import Quickshell
import QtQuick
import "Palettes"
import "../Config" as Cfg
import "../Models" as Models

Singleton {
    id: root

    // Currently selected color palette (raw from family)
    readonly property Models.ThemePalette currentPalette: getPalette(
        Cfg.Theme.paletteFamily,
        Cfg.Theme.paletteVariant
    )

    // Standardized color interface (direct bindings)
    readonly property color bg: currentPalette ? currentPalette.bg : "#000000"
    readonly property color fg: currentPalette ? currentPalette.fg : "#ffffff"
    readonly property color primary: currentPalette ? currentPalette.primary : "#0000ff"
    readonly property color secondary: currentPalette ? currentPalette.secondary : "#ff00ff"
    readonly property color accent: currentPalette ? currentPalette.accent : "#00ffff"
    readonly property color surface: currentPalette ? currentPalette.surface : "#333333"
    readonly property color error: currentPalette ? currentPalette.error : "#ff0000"
    readonly property color warning: currentPalette ? currentPalette.warning : "#ffff00"
    readonly property color success: currentPalette ? currentPalette.success : "#00ff00"
    readonly property color info: currentPalette ? currentPalette.info : "#0000ff"

    function getPalette(family, variant): Models.ThemePalette {
        // Use the new naming format: Family_Variant
        const paletteName = family + "_" + variant;
        
        // Return the Singleton object from Themes.Palettes module
        switch (paletteName) {
        case "Catppuccin_Mocha":
            return Catppuccin_Mocha;
        case "Catppuccin_Frappe":
            return Catppuccin_Frappe;
        case "Catppuccin_Latte":
            return Catppuccin_Latte;
        case "Catppuccin_Macchiato":
            return Catppuccin_Macchiato;
        case "Dracula_Dracula":
            return Dracula_Dracula;
        case "Dracula_Alucard":
            return Dracula_Alucard;
        default:
            console.warn("Unknown palette: " + paletteName + ", falling back to Catppuccin_Mocha");
            return Catppuccin_Mocha;
        }
    }

    function setPalette(family, variant) {
        Cfg.Theme.paletteFamily = family;
        Cfg.Theme.paletteVariant = variant;
    }

    function resetPalette() {
        Cfg.Theme.paletteFamily = Cfg.Theme.defaultFamily;
        Cfg.Theme.paletteVariant = Cfg.Theme.defaultVariant;
    }
}
