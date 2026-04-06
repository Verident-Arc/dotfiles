#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------------------
THEMES_DIR="$HOME/.config/hypr/themes"
QS_JSON="/tmp/qs_colors.json"
RELOAD_SCRIPT="$HOME/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"
WALL_DIR="$HOME/Images/Wallpapers"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------
apply_theme() {
    local theme_name="$1"
    local theme_file="${theme_name,,}"
    theme_file="${theme_file// /_}.json"
    local theme_path="$THEMES_DIR/$theme_file"
    
    echo "DEBUG: theme_name='$theme_name'"
    echo "DEBUG: theme_path='$theme_path'"

    if [[ ! -f "$theme_path" ]]; then
        echo "ERROR: Theme file not found at $theme_path"
        notify-send "Theme Switcher" "Theme file not found: $theme_file"
        return 1
    fi

    # Mapping to GTK themes
    declare -A gtk_themes
    gtk_themes["Catppuccin"]="catppuccin-mocha-blue-standard+default"
    gtk_themes["Gruvbox"]="Gruvbox-Dark"
    gtk_themes["Nord"]="Nordic"
    gtk_themes["Tokyo Night"]="Tokyonight-Dark"
    gtk_themes["Dracula"]="Dracula"
    gtk_themes["Rose Pine"]="rose-pine-gtk"

    local gtk_val="${gtk_themes[$theme_name]}"
    if [[ -n "$gtk_val" ]]; then
        echo "INFO: Setting GTK theme to '$gtk_val'"
        
        # 1. Try gsettings
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_val"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        
        # 2. Update config files (Fallback/Hard-set)
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_val/" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_val/" "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=\"$gtk_val\"/" "$HOME/.gtkrc-2.0" 2>/dev/null
        
        # XSettingsd (if running)
        if pgrep xsettingsd >/dev/null; then
            echo "Net/ThemeName \"$gtk_val\"" > ~/.config/xsettingsd/xsettingsd.conf
            killall -HUP xsettingsd
        fi
    fi

    # Use the 'blue' (primary) color from the theme JSON to generate a full palette
    local color_hex=$(grep -oP '"blue":\s*"\K#[0-9a-fA-F]+' "$theme_path")
    if [[ -n "$color_hex" ]]; then
        echo "INFO: Generating palette from color $color_hex"
        matugen color hex "$color_hex" --mode dark
    else
        # Fallback to direct JSON if color extraction fails
        matugen json "$theme_path"
    fi
    
    # 2. Apply a matching wallpaper if it exists
    local wall=$(find "$WALL_DIR" -maxdepth 1 -type f -iname "*${theme_name/ /}*" | head -n1)
    if [[ -n "$wall" ]]; then
        if command -v awww >/dev/null; then
            awww img "$wall" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
        fi
        cp "$wall" /tmp/lock_bg.png 2>/dev/null
    fi

    # 3. Reload everything
    bash "$RELOAD_SCRIPT"
}

# ------------------------------------------------------------------------------
# Main logic
# ------------------------------------------------------------------------------
if [[ -n "$1" ]]; then
    apply_theme "$1"
    exit 0
fi

themes=(
    "Catppuccin"
    "Gruvbox"
    "Nord"
    "Tokyo Night"
    "Dracula"
    "Rose Pine"
    "Dynamic (Matugen)"
)

choice=$(printf "%s\n" "${themes[@]}" | rofi -dmenu -i -p "Select Theme:" -title "Select Theme")

if [[ -z "$choice" ]]; then
    exit 0
fi

if [[ "$choice" == "Dynamic (Matugen)" ]]; then
    # Get current wallpaper
    if command -v swww >/dev/null; then
        img=$(swww query | grep -oE "/[^ ]+$" | head -n1)
    fi
    if [[ -z "$img" && -f "/tmp/lock_bg.png" ]]; then
        img="/tmp/lock_bg.png"
    fi
    
    if [[ -n "$img" ]]; then
        matugen image "$img" --source-color-index 0
        bash "$RELOAD_SCRIPT"
        notify-send "Theme Switcher" "Applied Dynamic theme"
    else
        notify-send "Theme Switcher" "No wallpaper found for dynamic theme"
        exit 1
    fi
else
    apply_theme "$choice"
    notify-send "Theme Switcher" "Applied $choice theme"
fi
