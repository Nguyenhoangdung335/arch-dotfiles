#!/bin/bash

WINDOW_CLASS="$1"

# Check if a window class argument was provided
if [ -z "$WINDOW_CLASS" ]; then
	echo "Usage: $0 <window_class> [command_to_run...]"
    dunstify "Error: No window class provided to launch_or_focus.sh"
	exit 1
fi

# Remove the first argument (the window class) from the list of arguments.
shift

if [ $# -eq 0 ]; then
	COMMAND="$WINDOW_CLASS"
else
	COMMAND="$@"
fi

if hyprctl clients | grep -q -i "class: ^${WINDOW_CLASS}$"; then
    # If the window exists, focus it.
    hyprctl dispatch focuswindow "^(${WINDOW_CLASS})$"
else
    # If the window does not exist, launch the application.
    # `exec` replaces the script process with the new application process.
    exec $COMMAND
fi
