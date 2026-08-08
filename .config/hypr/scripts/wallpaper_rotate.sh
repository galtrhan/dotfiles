#!/bin/bash

# Wallpaper rotation script for hyprpaper
# Usage: ./wallpaper_rotate.sh [interval_minutes]
# Default interval: 30 minutes

# Configuration
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
COLLECTION_DIR="$WALLPAPER_DIR/Collection"
DEFAULT_INTERVAL=30

# Get interval from argument or use default
INTERVAL=${1:-$DEFAULT_INTERVAL}

# Function to get random wallpaper
get_random_wallpaper() {
    # Find all image files in wallpaper directory
    find "$WALLPAPER_DIR" -path "$COLLECTION_DIR" -prune -o -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) -print | shuf -n 1
}

# Function to change wallpaper
change_wallpaper() {
    local wallpaper_path="$1"
    if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
        # First preload the wallpaper
        hyprctl hyprpaper preload "$wallpaper_path"
        
        # Then set it as wallpaper
        hyprctl hyprpaper wallpaper ",$wallpaper_path"
        
        # Save the wallpaper state for persistence
        echo "$wallpaper_path" > "$HOME/.config/hypr/wallpaper_state"
        
        # Clean up old loaded wallpapers (keep only last 5 to save memory)
        cleanup_old_wallpapers
        
        # Show notification
        local filename=$(basename "$wallpaper_path")
        notify-send -a "Wallpaper" -u normal -t 3000 -i "$wallpaper_path" "Wallpaper Changed" "$filename"
        
        echo "Changed wallpaper to: $wallpaper_path"
    else
        echo "No valid wallpaper found in: $WALLPAPER_DIR"
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

# Function to rotate wallpapers continuously
rotate_wallpapers() {
    echo "Starting wallpaper rotation every $INTERVAL minutes..."
    echo "Wallpaper directory: $WALLPAPER_DIR"
    
    while true; do
        # Get random wallpaper
        local wallpaper=$(get_random_wallpaper)
        
        # Change wallpaper
        change_wallpaper "$wallpaper"
        
        # Wait for specified interval
        sleep $((INTERVAL * 60))
    done
}

# Main execution
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [interval_minutes]"
    echo "  interval_minutes: Time between wallpaper changes (default: $DEFAULT_INTERVAL)"
    echo "  --help, -h: Show this help message"
    exit 0
fi

# Check if wallpaper directory exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Error: Wallpaper directory not found: $WALLPAPER_DIR"
    echo "Please create the directory and add some wallpapers, or modify WALLPAPER_DIR in this script."
    exit 1
fi

# Check if hyprctl is available
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found. Make sure Hyprland is running."
    exit 1
fi

# Start rotation
rotate_wallpapers
