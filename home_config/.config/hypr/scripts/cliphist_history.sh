#!/usr/bin/env bash

# --- Configuration ---
TMP_DIR="/tmp/cliphist-images"
ROFI_CMD="rofi -dmenu -i"

# UPDATE THESE PATHS
THEME_TEXT="~/.config/rofi/themes/clipboard-list.rasi"
THEME_IMG="~/.config/rofi/themes/clipboard-image.rasi"

# Ensure cache directory exists
mkdir -p "$TMP_DIR"

# --- Functions ---

# 1. Text Mode
show_text() {
    cliphist list | \
        gawk '!/binary.*(jpg|jpeg|png|bmp)/' | \
        # Add a null icon delimiter to every line so Rofi displays a generic icon
        sed 's/$/\x00icon\x1fcliphist/' | \
        $ROFI_CMD -p "Copy" -theme "$THEME_TEXT" | \
        cliphist decode | wl-copy
}

# 2. Image Mode (Optimized)
show_images() {
    # Generate previews using a highly optimized loop.
    # We check if the file exists before decoding to speed up subsequent launches.
    
    current_list=$(cliphist list | grep -E "binary.*(jpg|jpeg|png|bmp)")

    # We use a subshell and loop to decode only missing files
    while read -r line; do
        id=$(echo "$line" | cut -f1)
        ext=$(echo "$line" | grep -oE "(jpg|jpeg|png|bmp)$")
        filename="${id}.${ext}"
        filepath="${TMP_DIR}/${filename}"

        # Only decode if file doesn't exist
        if [[ ! -f "$filepath" ]]; then
            cliphist decode "$id" > "$filepath"
        fi
        
        # Output for Rofi (Format: Text \0icon\x1fPath)
        # We output the ID as the text so we can capture it later
        echo -en "${line}\0icon\x1f${filepath}\n"
    done <<< "$current_list" | \
        $ROFI_CMD -show-icons -p "Images" -theme "$THEME_IMG" | \
        cut -f1 | cliphist decode | wl-copy
}

# 3. All Mode (Standard)
show_all() {
    cliphist list | \
        # $ROFI_CMD -p "All" -theme "$THEME_TEXT" | \
        $ROFI_CMD -p "All" -theme "$THEME_TEXT" | \
        cliphist decode | wl-copy
}

# 4. Wipe/Delete (Optional utility)
wipe_history() {
    if rofi -dmenu -theme "$THEME_TEXT" -p "Clear History?" -mesg "Type 'yes' to confirm" | grep -q "yes"; then
        cliphist wipe
        notify-send "Clipboard" "History cleared"
    fi
}

# --- Main Logic ---
case "$1" in
    "text")   show_text ;;
    "images") show_images ;;
    "all")    show_all ;;
    "wipe")   wipe_history ;;
    *)        echo "Usage: $0 [text|images|all|wipe]" ;;
esac
