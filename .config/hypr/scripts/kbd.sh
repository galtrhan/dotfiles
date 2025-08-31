#!/bin/bash

# Sets the keyboard backlight to the next level in a cycle of 0, 1, 2
# Used & tested only on ThinkPad X1 Yoga 3rd Gen
#
# Usage: ./kbd.sh [0|1|2|restore]
# 0 - Off
# 1 - Low
# 2 - High
# restore - Restore previous state

# File containing the keyboard backlight brightness
BACKLIGHT_FILE="/sys/class/leds/tpacpi::kbd_backlight/brightness"
STATES=("Off" "Low" "High")
STATE_HISTORY_FILE="/tmp/kbd_backlight_previous"
NOTIFICATION_ID=130

# Check if the backlight file exists
if [[ ! -f "$BACKLIGHT_FILE" ]]; then
    echo "Backlight control file not found: $BACKLIGHT_FILE"
    exit 1
fi

# If parameter is provided, use it directly
if [[ $# -eq 1 ]]; then
    if [[ $1 == "restore" ]]; then
        # Restore previous state if history file exists
        if [[ -f "$STATE_HISTORY_FILE" ]]; then
            NEW_BRIGHTNESS=$(cat "$STATE_HISTORY_FILE")
        else
            echo "No previous state found"
            exit 1
        fi
    elif [[ $1 =~ ^[0-2]$ ]]; then
        # Save current state before changing
        cat "$BACKLIGHT_FILE" > "$STATE_HISTORY_FILE"
        NEW_BRIGHTNESS=$1
    else
        echo "Invalid brightness level. Please use 0, 1, 2, or 'restore'"
        exit 1
    fi
else
    # Save current state before changing
    cat "$BACKLIGHT_FILE" > "$STATE_HISTORY_FILE"
    # Get current brightness and calculate next level (0->1->2->0)
    CURRENT_BRIGHTNESS=$(cat "$BACKLIGHT_FILE")
    NEW_BRIGHTNESS=$(( (CURRENT_BRIGHTNESS + 1) % 3 ))
fi

# Set the new brightness level
echo "$NEW_BRIGHTNESS" | sudo tee "$BACKLIGHT_FILE" > /dev/null

# Show notification
if [[ $NEW_BRIGHTNESS -eq 0 ]]; then
    dunstify -a "Keyboard" -r "$NOTIFICATION_ID" -u critical -t 3000 -i keyboard-brightness -h int:value:0 "Keyboard Backlight" "Backlight Off"
else
    dunstify -a "Keyboard" -r "$NOTIFICATION_ID" -u normal -t 3000 -i keyboard-brightness -h int:value:"$(( NEW_BRIGHTNESS * 50 ))" "Keyboard Backlight" "Backlight ${STATES[$NEW_BRIGHTNESS]}"
fi

# Output the new brightness level
echo "Keyboard backlight set to level $NEW_BRIGHTNESS"
