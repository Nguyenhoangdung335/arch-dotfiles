#!/bin/bash

# A script to swap the window contents of the active workspaces on the first two monitors in Hyprland.

# --- DEPENDENCY CHECK ---
if ! command -v jq &> /dev/null; then
    notify-send "Hyprland Script Error" "'jq' is not installed. Please install it manually."
    exit 1
fi

# --- STAGE 1: CAPTURE INITIAL STATE ---
# Get the JSON data for all monitors and find the currently focused monitor's name and workspace ID.
# This ensures focus is returned to the correct place after the swap.
MONITOR_DATA=$(hyprctl monitors -j)
FOCUSED_MONITOR_ID=$(hyprctl activewindow -j | jq '.monitor')

# Fallback in case no window is focused (e.g., on an empty workspace)
if [ -z "$FOCUSED_MONITOR_ID" ] || [ "$FOCUSED_MONITOR_ID" == "null" ]; then
    FOCUSED_MONITOR_ID=$(echo "$MONITOR_DATA" | jq '.[0].id')
fi

FOCUSED_MONITOR_NAME=$(echo "$MONITOR_DATA" | jq -r ".[] | select(.id == $FOCUSED_MONITOR_ID) | .name")
FOCUSED_WORKSPACE_ID=$(echo "$MONITOR_DATA" | jq -r ".[] | select(.id == $FOCUSED_MONITOR_ID) | .activeWorkspace.id")


# --- STAGE 2: GET WORKSPACE INFO FOR SWAPPING ---
if [ $(echo "$MONITOR_DATA" | jq 'length') -lt 2 ]; then
    notify-send "Hyprland" "Two monitors are required to swap window contents."
    exit 1
fi

WORKSPACE1_ID=$(echo "$MONITOR_DATA" | jq -r '.[0].activeWorkspace.id')
WORKSPACE2_ID=$(echo "$MONITOR_DATA" | jq -r '.[1].activeWorkspace.id')

# Prevent swapping with special workspaces, as it can have unintended side effects.
if [ "$WORKSPACE1_ID" -lt 1 ] || [ "$WORKSPACE2_ID" -lt 1 ]; then
    notify-send "Hyprland" "Cannot swap windows with a special workspace."
    exit 1
fi

# Define a temporary workspace unlikely to be in use.
TEMP_WORKSPACE=99


# --- STAGE 3: THE 3-STAGE WINDOW SWAP ---
# Use 'movetoworkspacesilent' to prevent focus from changing during the moves.

# Move windows from Workspace 1 -> Temp
hyprctl clients -j | jq -r --argjson ws1 "$WORKSPACE1_ID" '.[] | select(.workspace.id == $ws1) | .address' | while read -r address; do
    hyprctl dispatch movetoworkspacesilent "$TEMP_WORKSPACE,address:$address"
done

# Move windows from Workspace 2 -> Workspace 1
hyprctl clients -j | jq -r --argjson ws2 "$WORKSPACE2_ID" '.[] | select(.workspace.id == $ws2) | .address' | while read -r address; do
    hyprctl dispatch movetoworkspacesilent "$WORKSPACE1_ID,address:$address"
done

# Move windows from Temp -> Workspace 2
hyprctl clients -j | jq -r --argjson tmp_ws "$TEMP_WORKSPACE" '.[] | select(.workspace.id == $tmp_ws) | .address' | while read -r address; do
    hyprctl dispatch movetoworkspacesilent "$WORKSPACE2_ID,address:$address"
done


# --- STAGE 4: RESTORE FOCUS INTELLIGENTLY ---
# 1. Focus the monitor that was active when the script was run.
hyprctl dispatch focusmonitor "$FOCUSED_MONITOR_NAME"

# 2. Find the address of the first window on that monitor's active workspace.
FIRST_WINDOW_ADDR=$(hyprctl clients -j | jq -r --argjson ws "$FOCUSED_WORKSPACE_ID" '(.[] | select(.workspace.id == $ws)) | .address' | head -n 1)

# 3. If a window exists on that workspace, focus it to allow immediate keyboard use.
if [ -n "$FIRST_WINDOW_ADDR" ]; then
    hyprctl dispatch focuswindow "address:$FIRST_WINDOW_ADDR"
fi
