#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------------------
WALL_DIR="$HOME/Images/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
ROFI_CONF="$HOME/.config/rofi/wallpaper.rasi"
RELOAD_SCRIPT="$HOME/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"
ADD_SCRIPT="$HOME/.config/hypr/scripts/quickshell/wallpaper/add_custom_wallpaper.sh"

mkdir -p "$THUMB_DIR"

# ------------------------------------------------------------------------------
# Discovery
# ------------------------------------------------------------------------------
mapfile -t wallpapers < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -printf "%f\n" | sort)

# ------------------------------------------------------------------------------
# Generate missing thumbnails
# ------------------------------------------------------------------------------
for wall in "${wallpapers[@]}"; do
    ext="${wall##*.}"
    thumb=""
    if [[ "${ext,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
        thumb="$THUMB_DIR/000_$wall"
        if [ ! -f "$thumb" ]; then
            ffmpeg -y -ss 00:00:05 -i "$WALL_DIR/$wall" -vframes 1 -f image2 -q:v 2 "$thumb" >/dev/null 2>&1 &
        fi
    else
        thumb="$THUMB_DIR/$wall"
        if [ ! -f "$thumb" ]; then
            magick "$WALL_DIR/$wall" -resize x420 -quality 70 "$thumb" >/dev/null 2>&1 &
        fi
    fi
done
wait # Wait for background thumb generation

# ------------------------------------------------------------------------------
# Prepare Rofi Input
# ------------------------------------------------------------------------------
function build_input() {
    printf ". random\0icon\x1fmedia-playlist-shuffle\n"
    printf "+ Add Custom\0icon\x1flist-add\n"
    for wall in "${wallpapers[@]}"; do
        ext="${wall##*.}"
        thumb_path=""
        if [[ "${ext,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
            thumb_path="$THUMB_DIR/000_$wall"
        else
            thumb_path="$THUMB_DIR/$wall"
        fi
        printf "%s\0icon\x1f%s\n" "$wall" "$thumb_path"
    done
}

# ------------------------------------------------------------------------------
# Show Rofi
# ------------------------------------------------------------------------------
# Use -show-icons on CLI as well to force it for dmenu mode
choice=$(build_input | rofi -dmenu -i -show-icons -theme "$ROFI_CONF" -p "Select Wallpaper" -title "Select Wallpaper")

if [ -z "$choice" ]; then
    exit 0
fi

# ------------------------------------------------------------------------------
# Actions
# ------------------------------------------------------------------------------
if [[ "$choice" == "+ Add Custom" ]]; then
    bash "$ADD_SCRIPT"
    exit 0
fi

if [[ "$choice" == ". random" ]]; then
    choice="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
fi

# Apply Wallpaper
full_path="$WALL_DIR/$choice"
ext="${choice##*.}"
transitions=("grow" "outer" "any" "wipe" "wave" "pixel" "center")
rand_trans="${transitions[$RANDOM % ${#transitions[@]}]}"

if [[ "${ext,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
    pkill mpvpaper || true
    mpvpaper -o 'loop --no-audio --hwdec=auto' '*' "$full_path" &
    thumb="$THUMB_DIR/000_$choice"
else
    pkill mpvpaper || true
    awww img "$full_path" --transition-type "$rand_trans" --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    thumb="$full_path"
fi

# Set lockscreen background
cp "$full_path" /tmp/lock_bg.png 2>/dev/null || cp "$thumb" /tmp/lock_bg.png

# Reload Colors (Matugen)
matugen image "$thumb" --source-color-index 0 && bash "$RELOAD_SCRIPT"

notify-send "Wallpaper Picker" "Applied $choice"
