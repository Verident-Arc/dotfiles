#!/usr/bin/env bash

# Log file for debugging
LOG_FILE="/tmp/qs_add_wallpaper.log"
echo "--- Starting Wallpaper Addition ---" > "$LOG_FILE"

# Define directories
WALL_DIR="$HOME/Images/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"

mkdir -p "$WALL_DIR"
mkdir -p "$THUMB_DIR"

echo "Directories prepared: $WALL_DIR, $THUMB_DIR" >> "$LOG_FILE"

# Selection
FILE=$(/usr/bin/zenity --file-selection --title="Select Wallpaper" --file-filter="Images & Videos | *.jpg *.jpeg *.png *.gif *.mp4 *.mkv *.mov *.webm")

if [ -z "$FILE" ]; then
    echo "No file selected." >> "$LOG_FILE"
    exit 0
fi

echo "Selected file: $FILE" >> "$LOG_FILE"

FILENAME=$(basename "$FILE")
DEST="$WALL_DIR/$FILENAME"

# Copy the file
if cp "$FILE" "$DEST"; then
    echo "Successfully copied to $DEST" >> "$LOG_FILE"
else
    echo "Failed to copy file!" >> "$LOG_FILE"
    notify-send "Wallpaper Picker" "Failed to copy wallpaper"
    exit 1
fi

# Generate thumbnail
extension="${FILENAME##*.}"
if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
    # Use quotes for DEST and thumbnail path
    if /usr/bin/ffmpeg -y -ss 00:00:05 -i "$DEST" -vframes 1 -f image2 -q:v 2 "$THUMB_DIR/000_$FILENAME" >> "$LOG_FILE" 2>&1; then
        echo "Video thumbnail generated." >> "$LOG_FILE"
    else
        echo "Video thumbnail generation failed." >> "$LOG_FILE"
    fi
else
    if /usr/bin/magick "$DEST" -resize x420 -quality 70 "$THUMB_DIR/$FILENAME" >> "$LOG_FILE" 2>&1; then
        echo "Image thumbnail generated." >> "$LOG_FILE"
    else
        echo "Image thumbnail generation failed." >> "$LOG_FILE"
    fi
fi

# Trigger refresh
touch "$WALL_DIR"
touch "$THUMB_DIR"

notify-send "Wallpaper Picker" "Added $FILENAME to library"
echo "--- Finished ---" >> "$LOG_FILE"
