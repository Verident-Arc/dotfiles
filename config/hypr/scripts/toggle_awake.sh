#!/usr/bin/env bash

# Toggle Always Awake (Caffeine mode)
if pgrep -x "hypridle" > /dev/null; then
    pkill -x "hypridle"
    notify-send -u low -i battery "Always Awake" "Enabled (Hypridle stopped)"
else
    hypridle &
    notify-send -u low -i battery "Always Awake" "Disabled (Hypridle started)"
fi
