#!/bin/bash

# Define paths
GIT_PROJECT_DIR="$HOME/git_projects"
DOTFILES="$GIT_PROJECT_DIR/arch-dotfiles"
PKG_DIR="$DOTFILES/packages"
NATIVE_FILE="$PKG_DIR/pkglist_native.txt"
AUR_FILE="$PKG_DIR/pkglist_aur.txt"

# Create directory if it doesn't exist
mkdir -p "$PKG_DIR"

# --- Helper Function to handle diffing and updating ---
update_and_diff() {
    local list_name="$1"
    local target_file="$2"
    local temp_file="$3"

    echo -e "\n::: Checking $list_name packages..."

    # Check if the target file exists for comparison
    if [ -f "$target_file" ]; then
        # Compare files. 
        # 'diff -u' gives a unified context (easier to read)
        # We suppress exit code so script continues even if diff finds changes
        if ! cmp -s "$target_file" "$temp_file"; then
            echo -e "  \033[1;33mChanges detected:\033[0m"
            # Show the diff with colors
            diff --color=always -u "$target_file" "$temp_file" | tail -n +1
            
            # Update the file
            mv "$temp_file" "$target_file"
            echo -e "  \033[1;32mUpdated $target_file\033[0m"
        else
            echo -e "  \033[1;30mNo changes.\033[0m"
            rm "$temp_file"
        fi
    else
        # First run case
        echo -e "  \033[1;34mFirst run detected. Creating $target_file...\033[0m"
        mv "$temp_file" "$target_file"
    fi
}

# 1. Generate Native List (Explicit only, removing AUR packages)
# We use a temporary file to hold the current system state
TEMP_NATIVE=$(mktemp)
comm -23 <(pacman -Qqe | sort) <(pacman -Qqm | sort) > "$TEMP_NATIVE"
update_and_diff "Native" "$NATIVE_FILE" "$TEMP_NATIVE"

# 2. Generate AUR List
TEMP_AUR=$(mktemp)
pacman -Qqm | sort > "$TEMP_AUR"
update_and_diff "AUR" "$AUR_FILE" "$TEMP_AUR"

echo -e "\n::: Done."
