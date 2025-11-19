#!/bin/bash

# Wallpaper persistence script
# Saves and restores the active wallpaper across restarts

WALLPAPER_STATE_FILE="$HOME/.config/hypr/wallpaper_state"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Function to save current wallpaper
save_wallpaper() {
    local wallpaper_path="$1"
    if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
        echo "$wallpaper_path" > "$WALLPAPER_STATE_FILE"
        echo "Saved wallpaper state: $wallpaper_path"
    else
        echo "Error: Invalid wallpaper path: $wallpaper_path"
        return 1
    fi
}

# Function to load saved wallpaper
load_wallpaper() {
    if [[ -f "$WALLPAPER_STATE_FILE" ]]; then
        local saved_wallpaper=$(cat "$WALLPAPER_STATE_FILE" 2>/dev/null)
        if [[ -n "$saved_wallpaper" && -f "$saved_wallpaper" ]]; then
            echo "Loading saved wallpaper: $saved_wallpaper"
            # Preload and set the wallpaper
            hyprctl hyprpaper preload "$saved_wallpaper"
            hyprctl hyprpaper wallpaper ",$saved_wallpaper"
            echo "Restored wallpaper: $saved_wallpaper"
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

# Function to get current active wallpaper
get_current_wallpaper() {
    hyprctl hyprpaper listactive | grep -E "eDP-1|DP-1|HDMI-1" | head -n1 | cut -d'=' -f2 | xargs
}

# Function to set wallpaper with persistence
set_wallpaper_with_persistence() {
    local wallpaper_path="$1"
    if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
        # Preload and set wallpaper
        hyprctl hyprpaper preload "$wallpaper_path"
        hyprctl hyprpaper wallpaper ",$wallpaper_path"
        
        # Save the state
        save_wallpaper "$wallpaper_path"
        
        echo "Set wallpaper with persistence: $wallpaper_path"
        return 0
    else
        echo "Error: Invalid wallpaper path: $wallpaper_path"
        return 1
    fi
}

# Function to clear saved state
clear_state() {
    rm -f "$WALLPAPER_STATE_FILE"
    echo "Cleared wallpaper state"
}

# Function to show current state
show_state() {
    if [[ -f "$WALLPAPER_STATE_FILE" ]]; then
        local saved_wallpaper=$(cat "$WALLPAPER_STATE_FILE")
        echo "Saved wallpaper: $saved_wallpaper"
        if [[ -f "$saved_wallpaper" ]]; then
            echo "Status: Valid"
        else
            echo "Status: File not found"
        fi
    else
        echo "No saved wallpaper state"
    fi
    
    echo "Current active wallpaper:"
    hyprctl hyprpaper listactive
}

# Main execution
case "${1:-help}" in
    "save")
        current_wallpaper=$(get_current_wallpaper)
        if [[ -n "$current_wallpaper" ]]; then
            save_wallpaper "$current_wallpaper"
        else
            echo "No active wallpaper found to save"
            exit 1
        fi
        ;;
    "load"|"restore")
        load_wallpaper
        ;;
    "set")
        if [[ -n "$2" ]]; then
            set_wallpaper_with_persistence "$2"
        else
            echo "Usage: $0 set <wallpaper_path>"
            exit 1
        fi
        ;;
    "clear")
        clear_state
        ;;
    "status"|"show")
        show_state
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  save                    - Save current wallpaper state"
        echo "  load|restore           - Load saved wallpaper"
        echo "  set <path>             - Set wallpaper and save state"
        echo "  clear                  - Clear saved state"
        echo "  status|show            - Show current state"
        echo "  help                   - Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
