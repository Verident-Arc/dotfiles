#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Manage Special Workspaces 1-4
# ------------------------------------------------------------------------------

STATE_FILE="/tmp/hypr_special_ws"
TOTAL_SPECIAL=4

# Get current special workspace state
if [ ! -f "$STATE_FILE" ]; then
    echo 1 > "$STATE_FILE"
fi
current_ws=$(cat "$STATE_FILE" 2>/dev/null || echo 1)

function toggle() {
    local ws=$1
    echo "$ws" > "$STATE_FILE"
    hyprctl dispatch togglespecialworkspace "$ws"
}

function cycle() {
    local direction=$1
    if [[ "$direction" == "next" ]]; then
        current_ws=$(( (current_ws % TOTAL_SPECIAL) + 1 ))
    else
        current_ws=$(( (current_ws - 2 + TOTAL_SPECIAL) % TOTAL_SPECIAL + 1 ))
    fi
    echo "$current_ws" > "$STATE_FILE"
    
    # Switch to the new special workspace
    hyprctl dispatch togglespecialworkspace "$current_ws"
}

case "$1" in
    "toggle")
        toggle "${2:-1}"
        ;;
    "cycle")
        cycle "${2:-next}"
        ;;
esac
