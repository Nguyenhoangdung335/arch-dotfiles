#!/bin/bash

SESSION_NAME="Hyprland"

# Check session existence (silently)
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session $SESSION_NAME already exists"
    exit 1
fi

tmux start-server

# Create session
tmux new-session -d -s "$SESSION_NAME" -n "Notes" -c "$HOME/notes/"

tmux new-window -d -t $SESSION_NAME:2 -n "Hyprland" -c "$HOME/.config/hypr/"

tmux new-window -d -t $SESSION_NAME:3 -n "Waybar" -c "$HOME/.config/waybar/"

tmux new-window -d -t $SESSION_NAME:4 -n "Terminal" -c "$HOME/"

# Attach to session
tmux select-window -t "$SESSION_NAME:1"
