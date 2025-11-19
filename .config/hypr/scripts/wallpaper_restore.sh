#!/bin/bash

# Wallpaper restore script for Hyprland startup
# This script restores the last active wallpaper on startup

WALLPAPER_STATE_FILE="$HOME/.config/hypr/wallpaper_state"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Wait for hyprpaper to be ready (reduced delay to minimize flickering)
sleep 0.5

# Function to restore wallpaper
restore_wallpaper() {
    if [[ -f "$WALLPAPER_STATE_FILE" ]]; then
        local saved_wallpaper=$(cat "$WALLPAPER_STATE_FILE" 2>/dev/null)
        if [[ -n "$saved_wallpaper" && -f "$saved_wallpaper" ]]; then
            echo "Restoring wallpaper: $saved_wallpaper"
            # Preload and set the wallpaper
            hyprctl hyprpaper preload "$saved_wallpaper"
            hyprctl hyprpaper wallpaper ",$saved_wallpaper"
            echo "Wallpaper restored successfully"
            return 0
        else
            echo "Saved wallpaper not found or invalid: $saved_wallpaper"
            rm -f "$WALLPAPER_STATE_FILE"
            return 1
        fi
    else
        echo "No saved wallpaper state found"
        return 1
    fi
}

# Function to set a random wallpaper if no saved state
set_random_wallpaper() {
    echo "Setting random wallpaper as fallback"
    local random_wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) | shuf -n 1)
    
    if [[ -n "$random_wallpaper" && -f "$random_wallpaper" ]]; then
        hyprctl hyprpaper preload "$random_wallpaper"
        hyprctl hyprpaper wallpaper ",$random_wallpaper"
        # Save this as the new state
        echo "$random_wallpaper" > "$WALLPAPER_STATE_FILE"
        echo "Set random wallpaper: $random_wallpaper"
    else
        echo "No wallpapers found in: $WALLPAPER_DIR"
        return 1
    fi
}

# Main execution
echo "Starting wallpaper restore..."

# Try to restore saved wallpaper
if ! restore_wallpaper; then
    echo "Failed to restore saved wallpaper, setting random wallpaper"
    set_random_wallpaper
fi

echo "Wallpaper restore completed"
