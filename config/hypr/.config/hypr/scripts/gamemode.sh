#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Toggle Hyprland Gamemode
# ------------------------------------------------------------------------------

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:rounding 0;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword input:sensitivity 0.0"
    notify-send "Gamemode" "Optimized for performance (Animations OFF)" -i controller
    exit
fi

hyprctl reload
notify-send "Gamemode" "Standard settings restored (Animations ON)" -i controller
