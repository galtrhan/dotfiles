#!/bin/bash

# Simple wallpaper change script for cron
# This script changes wallpaper once and exits

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
NOTIFICATION_ID=132

# Function to get random wallpaper
get_random_wallpaper() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) | shuf -n 1
}

# Function to change wallpaper
change_wallpaper() {
    local wallpaper_path="$1"
    if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
        # First preload the wallpaper
        hyprctl hyprpaper preload "$wallpaper_path"
        
        # Then set it as wallpaper
        hyprctl hyprpaper wallpaper ",$wallpaper_path"
        
        # Clean up old loaded wallpapers (keep only last 5 to save memory)
        cleanup_old_wallpapers
        
        # Show notification
        local filename=$(basename "$wallpaper_path")
        dunstify -a "Wallpaper" -r "$NOTIFICATION_ID" -u normal -t 3000 -i image "Wallpaper Changed" "$filename"
        
        echo "$(date): Changed wallpaper to: $filename"
    else
        echo "$(date): No valid wallpaper found in: $WALLPAPER_DIR"
    fi
}

# Function to clean up old loaded wallpapers
cleanup_old_wallpapers() {
    # Get list of loaded wallpapers
    local loaded_wallpapers=$(hyprctl hyprpaper listloaded 2>/dev/null | grep -v "^$")
    local count=$(echo "$loaded_wallpapers" | wc -l)
    
    # If more than 5 wallpapers are loaded, remove the oldest ones
    if [[ $count -gt 5 ]]; then
        local to_remove=$((count - 5))
        echo "$loaded_wallpapers" | head -n "$to_remove" | while read -r wallpaper; do
            if [[ -n "$wallpaper" ]]; then
                hyprctl hyprpaper unload "$wallpaper" 2>/dev/null
            fi
        done
    fi
}

# Check if wallpaper directory exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Error: Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Check if hyprctl is available
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found. Make sure Hyprland is running."
    exit 1
fi

# Change wallpaper once
wallpaper=$(get_random_wallpaper)
change_wallpaper "$wallpaper"
