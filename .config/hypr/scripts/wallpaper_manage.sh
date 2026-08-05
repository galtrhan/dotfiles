#!/bin/bash

# Wallpaper management script
# Usage: ./wallpaper_manage.sh [collect|discard]
#   collect - Move current wallpaper to ~/Pictures/Wallpapers/Collection/ and keep it active
#   discard - Delete current wallpaper and set the next one

SCRIPT_DIR="$HOME/.config/hypr/scripts"
WALLPAPER_STATE_FILE="$HOME/.config/hypr/wallpaper_state"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
COLLECTION_DIR="$WALLPAPER_DIR/Collection"

# Function to get current active wallpaper path
get_current_wallpaper() {
    local saved=""
    if [[ -f "$WALLPAPER_STATE_FILE" ]]; then
        saved=$(cat "$WALLPAPER_STATE_FILE" 2>/dev/null)
        if [[ -n "$saved" && -f "$saved" ]]; then
            echo "$saved"
            return 0
        fi
    fi
    hyprctl hyprpaper listactive 2>/dev/null | head -n1 | rev | cut -d':' -f1 | rev | xargs
}

# Function to get a random wallpaper
get_random_wallpaper() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) | shuf -n 1
}

# Function to move current wallpaper to the collection and keep it active
collect_wallpaper() {
    local current=$(get_current_wallpaper)
    if [[ -z "$current" || ! -f "$current" ]]; then
        notify-send -a "Wallpaper" -u normal -t 3000 "Wallpaper Collection" "No active wallpaper found"
        return 1
    fi

    mkdir -p "$COLLECTION_DIR"

    local filename=$(basename "$current")
    local target="$COLLECTION_DIR/$filename"

    if [[ "$current" != "$target" ]]; then
        if [[ -e "$target" ]]; then
            local base="${filename%.*}"
            local ext="${filename##*.}"
            local i=1
            while [[ -e "$COLLECTION_DIR/${base}_$i.$ext" ]]; do
                ((i++))
            done
            target="$COLLECTION_DIR/${base}_$i.$ext"
        fi
        mv "$current" "$target"
    fi

    "$SCRIPT_DIR/wallpaper_persistence.sh" set "$target"
    hyprctl hyprpaper unload "$current" 2>/dev/null

    notify-send -a "Wallpaper" -u normal -t 3000 -i "$target" "Wallpaper Collected" "$filename"
}

# Function to delete current wallpaper and set the next one
discard_wallpaper() {
    local current=$(get_current_wallpaper)
    if [[ -n "$current" && -f "$current" ]]; then
        rm -f "$current"
        hyprctl hyprpaper unload "$current" 2>/dev/null
    fi

    local next=$(get_random_wallpaper)
    if [[ -z "$next" || ! -f "$next" ]]; then
        notify-send -a "Wallpaper" -u normal -t 3000 "Wallpaper Discard" "No wallpapers left in $WALLPAPER_DIR"
        return 1
    fi

    "$SCRIPT_DIR/wallpaper_persistence.sh" set "$next"
    notify-send -a "Wallpaper" -u normal -t 3000 -i "$next" "Wallpaper Changed" "$(basename "$next")"
}

# Main execution
case "${1:-help}" in
    "collect"|"move")
        collect_wallpaper
        ;;
    "discard"|"delete")
        discard_wallpaper
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  collect - Move current wallpaper to $COLLECTION_DIR and keep it active"
        echo "  discard - Delete current wallpaper and set the next one"
        echo "  help    - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
