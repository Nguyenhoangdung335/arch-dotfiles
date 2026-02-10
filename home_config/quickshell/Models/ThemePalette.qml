// ./Models/ThemePalette.qml
import QtQuick

QtObject {
    // Metadata
    required property string family
    required property string variant
    required property list<color> previewColors
    // required property map<string, color> colors
    required property list<ColorName> colors
    required property bool isDark

    // Standard Interface
    required property color bg
    required property color fg
    required property color primary
    required property color secondary
    required property color accent
    required property color surface
    required property color error
    required property color warning
    required property color success
    required property color info

    // Default values
    property string emoji: "🎨"

    function getFullName(): string {
        return family + "_" + variant;
    }

    function getDisplayName(): string {
        return (family.charAt(0).toUpperCase() + family.slice(1)) + " " + (variant.charAt(0).toUpperCase() + variant.slice(1).replace("_", " "));
    }

    // Default logic for a contrast color
    function getContrastColor(bg: color): color {
        // Simple luminance check
        return (bg.r * 0.299 + bg.g * 0.587 + bg.b * 0.114) > 0.6 ? "#000000" : "#ffffff";
    }

    // A method intended to be overridden for specific logic (like Catppuccin accents)
    function getPrimaryPreviewColor(): color {
        return colors.length > 0 ? colors[0] : "transparent";
    }
}
