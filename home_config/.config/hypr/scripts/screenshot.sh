#!/bin/sh

# This script provides a flexible screenshotting utility for Hyprland.

# Set the directory where screenshots will be saved.
SCREENSHOT_DIR=~/Pictures/Screenshots

# Ensure the screenshot directory exists.
mkdir -p "$SCREENSHOT_DIR"

# Get the current date and time for the filename.
FILENAME="$SCREENSHOT_DIR/$(date +'%Y-%m-%d_%H-%M-%S.png')"

case "$1" in
"select")
	# Take a screenshot of a selected region and save it.
	grim -g "$(slurp)" "$FILENAME"
	;;
"select_edit")
	# Take a screenshot of a selected region and open it in swappy for editing.
	grim -g "$(slurp)" - | satty -f -
	;;
"select_copy")
	# Take a screenshot of a selected region and copy it to the clipboard.
	grim -g "$(slurp)" - | wl-copy
	;;
"screen")
	# Take a screenshot of the entire screen and save it.
	grim "$FILENAME"
	;;
"screen_edit")
	# Take a screenshot of the entire screen and open it in swappy for editing.
	grim - | satty -f -
	;;
"screen_copy")
	# Take a screenshot of the entire screen and copy it to the clipboard.
	grim - | wl-copy
	;;
*)
	echo "Usage: $0 {select|select_edit|select_copy|screen|screen_edit|screen_copy}"
	exit 1
	;;
esac
