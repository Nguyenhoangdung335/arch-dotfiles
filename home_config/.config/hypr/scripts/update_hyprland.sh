#!/bin/bash

# --- Configuration ---
HYPRLAND_GIT_DIR="$HOME/git_projects/Hyprland"
LOG_FILE="/tmp/hyprland_update.log"

# --- Colors for Output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Error handler
handle_error() {
    log_error "$1"
    echo "Check the log file at $LOG_FILE for details (if available)."
    exit 1
}

# --- Main Script ---

# 1. Update System Packages
log_info "Updating system packages with yay..."
yay -Syu || handle_error "System update failed."
log_success "System packages updated."

# 2. Check Directory
if [ ! -d "$HYPRLAND_GIT_DIR" ]; then
    handle_error "Directory $HYPRLAND_GIT_DIR does not exist. Please clone the repository first."
fi

# 3. Enter Directory
cd "$HYPRLAND_GIT_DIR" || handle_error "Failed to cd into $HYPRLAND_GIT_DIR"
log_info "Working directory: $(pwd)"

# 4. Git Pull
log_info "Pulling latest changes from Git..."
output=$(git pull)
if [ $? -ne 0 ]; then
    handle_error "Git pull failed."
fi

# Check if there were actual changes
if [[ "$output" == *"Already up to date."* ]]; then
    log_warn "Repository is already up to date."
    read -p "Force rebuild anyway? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Exiting without rebuild."
        exit 0
    fi
fi

# 5. Clean Build (Optional but Recommended)
# Removing the old build folder prevents caching errors when dependencies change
log_info "Cleaning previous build artifacts..."
make clean > /dev/null 2>&1
# specific to Hyprland's CMake structure, sometimes deleting build/ is safer
rm -rf build 

# 6. Build Hyprland
# -j$(nproc) tells make to use all available CPU cores
log_info "Building Hyprland (using $(nproc) cores)..."
make all -j$(nproc) || handle_error "Compilation failed."

# 7. Install
log_info "Installing Hyprland..."
sudo make install || handle_error "Installation failed."

# 8. Final Success
echo ""
log_success "----------------------------------------------------"
log_success "Hyprland and system packages successfully updated!"
log_success "You may need to logout or restart Hyprland to see changes."
log_success "----------------------------------------------------"
