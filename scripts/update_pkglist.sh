#!/bin/bash

# Define paths
GIT_PROJECT_DIR="$HOME/git_projects"
DOTFILES="$GIT_PROJECT_DIR/arch-dotfiles"
PKG_DIR="$DOTFILES/packages"
NATIVE_FILE="$PKG_DIR/pkglist_native.txt"
AUR_FILE="$PKG_DIR/pkglist_aur.txt"

# Create directory if it doesn't exist
mkdir -p "$PKG_DIR"

# Convert a list of package names into "name version" lines
list_with_versions() {
    local input_file="$1"
    local output_file="$2"

    : > "$output_file"
    while IFS= read -r pkg; do
        # pacman -Q prints: "name version"
        pacman -Q "$pkg" 2>/dev/null
    done < "$input_file" | sort > "$output_file"
}

# --- Helper Function to handle diffing and updating ---
update_and_diff() {
    local list_name="$1"
    local target_file="$2"
    local temp_file="$3"

    echo -e "\n::: Checking $list_name packages..."

    if [ -f "$target_file" ]; then
        if ! cmp -s "$target_file" "$temp_file"; then
            echo -e "  \033[1;33mChanges detected:\033[0m"
            diff --color=always -u "$target_file" "$temp_file" | tail -n +1

            mv "$temp_file" "$target_file"
            echo -e "  \033[1;32mUpdated $target_file\033[0m"
        else
            echo -e "  \033[1;30mNo changes.\033[0m"
            rm "$temp_file"
        fi
    else
        echo -e "  \033[1;34mFirst run detected. Creating $target_file...\033[0m"
        mv "$temp_file" "$target_file"
    fi
}

# 1. Generate Native List (Explicit only, removing AUR packages)
TEMP_NATIVE_NAMES=$(mktemp)
comm -23 <(pacman -Qqe | sort) <(pacman -Qqm | sort) > "$TEMP_NATIVE_NAMES"

TEMP_NATIVE=$(mktemp)
list_with_versions "$TEMP_NATIVE_NAMES" "$TEMP_NATIVE"
rm -f "$TEMP_NATIVE_NAMES"

update_and_diff "Native" "$NATIVE_FILE" "$TEMP_NATIVE"

# 2. Generate AUR List
TEMP_AUR_NAMES=$(mktemp)
pacman -Qqm | sort > "$TEMP_AUR_NAMES"

TEMP_AUR=$(mktemp)
list_with_versions "$TEMP_AUR_NAMES" "$TEMP_AUR"
rm -f "$TEMP_AUR_NAMES"

update_and_diff "AUR" "$AUR_FILE" "$TEMP_AUR"

echo -e "\n::: Done."
