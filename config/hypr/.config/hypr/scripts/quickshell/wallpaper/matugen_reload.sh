#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# 1. Flatten Matugen v4.0 Nested JSON for Quickshell
# ------------------------------------------------------------------------------
QS_JSON="/tmp/qs_colors.json"

python3 -c '
import json
import sys
import os

def flatten_colors(obj):
    if isinstance(obj, dict):
        if "color" in obj and isinstance(obj["color"], str):
            return obj["color"]
        return {k: flatten_colors(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [flatten_colors(x) for x in obj]
    return obj

target_file = sys.argv[1]
if not os.path.exists(target_file):
    sys.exit(0)

try:
    with open(target_file, "r") as f:
        data = json.load(f)
    
    flat_data = flatten_colors(data)
    
    with open(target_file, "w") as f:
        json.dump(flat_data, f, indent=4)
        
except Exception as e:
    print(f"Error flattening JSON: {e}")
' "$QS_JSON"

# ------------------------------------------------------------------------------
# 2. Update theme.rasi with colors from /tmp/qs_colors.json
# ------------------------------------------------------------------------------
python3 -c '
import json
import re
import os
import sys

qs_json = "/tmp/qs_colors.json"
rasi_file = os.path.expanduser("~/.config/rofi/theme.rasi")

if not os.path.exists(qs_json) or not os.path.exists(rasi_file):
    sys.exit(0)

try:
    with open(qs_json, "r") as f:
        colors = json.load(f)

    with open(rasi_file, "r") as f:
        content = f.read()

    # Map JSON keys to RASI variables
    mapping = {
        "bg-col": "base",
        "bg-col-light": "mantle",
        "border-col": "surface2",
        "selected-col": "surface1",
        "blue": "blue",
        "fg-col": "text",
        "fg-col2": "red",
        "grey": "subtext0",
        "surface0": "surface0",
        "surface1": "surface1",
        "mauve": "mauve",
        "rosewater": "pink"
    }

    for rasi_var, json_key in mapping.items():
        if json_key in colors:
            val = colors[json_key]
            # Match "var-name: #hex;" with any amount of spacing
            pattern = fr"({rasi_var}:\s*)#[0-9a-fA-F]+;"
            content = re.sub(pattern, fr"\1{val};", content)

    # Update alphas and gradients based on new colors
    if "base" in colors:
        content = re.sub(r"(bg-alpha:\s*)#[0-9a-fA-F]+;", r"\1" + colors["base"] + "f2;", content)
    if "surface1" in colors:
        content = re.sub(r"(surface-alpha:\s*)#[0-9a-fA-F]+;", r"\1" + colors["surface1"] + "80;", content)
    
    if "surface1" in colors and "surface0" in colors:
        # Match gradient with any hex colors
        grad_pattern = r"(active-grad:\s*linear-gradient\(to bottom, )#[0-9a-fA-F]+, #[0-9a-fA-F]+(\);)"
        content = re.sub(grad_pattern, r"\1" + colors["surface1"] + ", " + colors["surface0"] + r"\2", content)
    
    if "mauve" in colors and "blue" in colors:
        tab_grad_pattern = r"(tab-grad:\s*linear-gradient\(to right, )#[0-9a-fA-F]+, #[0-9a-fA-F]+(\);)"
        content = re.sub(tab_grad_pattern, r"\1" + colors["mauve"] + ", " + colors["blue"] + r"\2", content)

    with open(rasi_file, "w") as f:
        f.write(content)
except Exception as e:
    print(f"Error updating RASI: {e}")
'

# ------------------------------------------------------------------------------
# 3. Flatten Matugen v4.0 Output in Standard Text Configs
# ------------------------------------------------------------------------------
TEXT_FILES=(
    "/tmp/kitty-matugen-colors.conf"
    "$HOME/.config/nvim/matugen_colors.lua"
    "$HOME/.config/cava/colors"
    "$HOME/.config/swayosd/style.css"
    "$HOME/.config/swaync/style.css"
)

for file in "${TEXT_FILES[@]}"; do
    if [ -f "$file" ] && [ -w "$file" ]; then
        sed -i -E 's/\{[[:space:]]*"color":[[:space:]]*"([^"]+)"[[:space:]]*\}/\1/g' "$file"
    fi
done

# ------------------------------------------------------------------------------
# 4. GTK Theme & Dark Mode
# ------------------------------------------------------------------------------
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Flat-Remix-GTK-Blue-Dark'
fi

# ------------------------------------------------------------------------------
# 5. Reload System Components
# ------------------------------------------------------------------------------
hyprctl reload 2>/dev/null

# Reload Kitty
killall -USR1 kitty 2>/dev/null

# Reload Cava
if pgrep -x "cava" > /dev/null; then
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    killall -USR1 cava
fi

# Reload SwayNC
if command -v swaync-client &> /dev/null; then
    swaync-client -rs
fi

# Reload SwayOSD
if systemctl --user is-active --quiet swayosd.service; then
    systemctl --user restart swayosd.service &
fi

# Refresh Quickshell TopBar (if needed, usually it watches files)
# pkill -USR1 quickshell 2>/dev/null

notify-send "Matugen" "Theme synchronized across the desktop"
wait
