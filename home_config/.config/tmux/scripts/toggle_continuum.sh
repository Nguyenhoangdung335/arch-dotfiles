#!/bin/bash 

TMUX_CONF="$HOME/.config/tmux/tmux.conf"

if [ ! -f "$TMUX_CONF" ]; then
    echo "Error: tmux configuration file not found at $TMUX_CONF"
    exit 1
fi

if grep -q "set -g @continuum-restore 'on'" "$TMUX_CONF"; then
    # If it's on, turn it off
    sed -i "s/set -g @continuum-restore 'on'/set -g @continuum-restore 'off'/" "$TMUX_CONF"
    tmux set-option -g @continuum-restore 'off'
    tmux display-message 'Continuum auto-restore OFF (persistent)'
else
    # If it's off or not present, turn it on
    # This handles both the 'off' case and the case where the line might be missing
    sed -i "s/set -g @continuum-restore 'off'/set -g @continuum-restore 'on'/" "$TMUX_CONF"
    tmux set-option -g @continuum-restore 'on'
    tmux display-message 'Continuum auto-restore ON (persistent)'
fi
