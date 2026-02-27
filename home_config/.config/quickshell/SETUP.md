# Quickshell Theme Switcher Setup Guide

## 🎨 Overview
A floating glassmorphism theme switcher widget for Arch Linux + Hyprland with Material Design principles.

## 📋 Components Created

### Core Theme System
- **[Themes/Theme.qml](Themes/Theme.qml)**: Main theme singleton with palette mapping
- **[Config/Theme.qml](Config/Theme.qml)**: Configuration singleton for theme persistence
- **[Modules/ThemeSwitcher/ThemeSwitcher.qml](Modules/ThemeSwitcher/ThemeSwitcher.qml)**: Full theme switcher panel
- **[Modules/ThemeSwitcher/FloatingThemeSwitcher.qml](Modules/ThemeSwitcher/FloatingThemeSwitcher.qml)**: Floating widget

### Material UI Components
- **[Components/GlassCard.qml](Components/GlassCard.qml)**: Reusable glassmorphism card
- **[Components/MaterialButton.qml](Components/MaterialButton.qml)**: Button with ripple effect
- **[Components/ThemeToggleButton.qml](Components/ThemeToggleButton.qml)**: Floating action button
- **[Components/ThemeMenuCard.qml](Components/ThemeMenuCard.qml)**: Compact theme menu
- **[Components/VariantChip.qml](Components/VariantChip.qml)**: Theme variant chips

## 🚀 Launch Methods

### Method 1: Direct Launch (Testing)
```bash
# Launch the floating theme switcher
quickshell -c ~/.config/quickshell/theme_switcher.qml

# Or use the full panel version for testing
quickshell -c ~/.config/quickshell/test_switcher.qml
```

### Method 2: Using Launch Script
```bash
# Run the launcher script
~/.config/quickshell/launch_theme_switcher.sh

# Or add to PATH and run from anywhere
./launch_theme_switcher.sh
```

### Method 3: Hyprland Auto-Start (Recommended)
Add to your `~/.config/hypr/hyprland.conf`:

```conf
# Quickshell Theme Switcher
exec-once = quickshell -c ~/.config/quickshell/theme_switcher.qml
```

### Method 4: Hyprland Keybinding
Add to your `~/.config/hypr/hyprland.conf`:

```conf
# Toggle theme switcher with Super + T
bind = SUPER, T, exec, ~/.config/quickshell/launch_theme_switcher.sh
```

## 🔧 Installation Steps

### 1. Link Configuration (if not already done)
```bash
# Create symlink from repo to config directory
ln -sf ~/git_projects/arch-dotfiles/home_config/quickshell ~/.config/quickshell
```

### 2. Verify Quickshell Installation
```bash
# Check if quickshell is installed
which quickshell

# If not installed on Arch:
yay -S quickshell-git
# or
paru -S quickshell-git
```

### 3. Test the Widget
```bash
# Test the floating widget
quickshell -c ~/.config/quickshell/theme_switcher.qml

# Test the full panel
quickshell -c ~/.config/quickshell/test_switcher.qml
```

### 4. Add to Hyprland Startup
```bash
# Edit your Hyprland config
nvim ~/.config/hypr/hyprland.conf

# Add this line in the exec-once section:
exec-once = quickshell -c ~/.config/quickshell/theme_switcher.qml

# Reload Hyprland
hyprctl reload
```

## 🎯 Usage

### Floating Widget
1. A floating button (🎨) appears in the bottom-right corner
2. Click it to expand the theme menu
3. Select any theme from the list
4. Theme changes apply instantly

### Keyboard Control (Optional)
Add keybinding in `~/.config/hypr/hyprland.conf`:
```conf
# Super + Shift + T to restart theme switcher
bind = SUPER_SHIFT, T, exec, pkill -f "quickshell.*theme_switcher" && quickshell -c ~/.config/quickshell/theme_switcher.qml
```

## 🎨 Available Themes

### Catppuccin
- 🌙 Mocha (Dark)
- ☕ Frappe (Dark)
- 🥛 Latte (Light)
- 🍵 Macchiato (Dark)

### Dracula
- 🧛 Dracula (Dark)
- ⚔️ Alucard (Dark)

## 🔍 Troubleshooting

### Widget doesn't appear
```bash
# Check if quickshell is running
pgrep -a quickshell

# Check logs
journalctl --user -u quickshell -f
```

### Theme not changing
- Verify palette files exist in `~/.config/quickshell/Themes/Palettes/`
- Check for QML errors: Run with debug output
```bash
QT_LOGGING_RULES="*.debug=true" quickshell -c ~/.config/quickshell/theme_switcher.qml
```

### Window positioning issues
- Adjust anchor margins in [FloatingThemeSwitcher.qml](Modules/ThemeSwitcher/FloatingThemeSwitcher.qml#L17-L21)

## 📝 Customization

### Change Position
Edit [FloatingThemeSwitcher.qml](Modules/ThemeSwitcher/FloatingThemeSwitcher.qml):
```qml
anchor {
    left: true    // Change to left side
    top: true     // Change to top
    margins {
        left: 24
        top: 24
    }
}
```

### Add More Themes
1. Create palette file: `Themes/Palettes/<Family>_<Variant>.qml`
2. Add family and variant properties inside the file
3. Register in `Themes/Palettes/qmldir`
4. Import and add case in `Themes/Theme.qml`
5. ThemeSwitcher will auto-discover it!

See `Themes/Palettes/Example_Template.qml.disabled` for a template.

## 🐛 Bug Fixes Applied

✅ Fixed syntax error in Theme.qml (incomplete property)  
✅ Removed commented import in Config/Theme.qml  
✅ Fixed Repeater visibility logic in ThemeSwitcher  
✅ Created proper palette mapping system for different families  
✅ Standardized color interface (bg, fg, primary, secondary, etc.)  
✅ Added qmldir files for proper module registration

## 🎯 Features

- 🎨 6 pre-configured themes (Catppuccin + Dracula families)
- 🪟 Glassmorphism with backdrop blur
- 💫 Material Design ripple effects
- 🎭 Smooth animations and transitions
- 🔄 Instant theme switching
- 📦 Modular, reusable components
- 🚀 Auto-discovery of new themes
