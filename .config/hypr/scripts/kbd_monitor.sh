#!/bin/bash

# Monitor keyboard backlight changes and show notifications
# Works with system keyboard shortcuts and manual changes
#
# Usage: ./kbd_monitor.sh [start|stop]
# start - Start monitoring (runs in background)
# stop - Stop monitoring

BACKLIGHT_FILE="/sys/class/leds/tpacpi::kbd_backlight/brightness"
STATES=("Off" "Low" "High")
NOTIFICATION_ID=130
PID_FILE="/tmp/kbd_monitor.pid"

# Check if the backlight file exists
if [[ ! -f "$BACKLIGHT_FILE" ]]; then
    echo "Backlight control file not found: $BACKLIGHT_FILE"
    exit 1
fi

# Function to show notification
show_notification() {
    local brightness=$1
    if [[ $brightness -eq 0 ]]; then
        dunstify -a "Keyboard" -r "$NOTIFICATION_ID" -u critical -t 3000 -i keyboard-brightness -h int:value:0 "Keyboard Backlight" "Backlight Off"
    else
        dunstify -a "Keyboard" -r "$NOTIFICATION_ID" -u normal -t 3000 -i keyboard-brightness -h int:value:"$(( brightness * 50 ))" "Keyboard Backlight" "Backlight ${STATES[$brightness]}"
    fi
}

# Function to monitor backlight changes
monitor_backlight() {
    local last_brightness=$(cat "$BACKLIGHT_FILE")
    
    # Show initial state
    show_notification "$last_brightness"
    
    # Monitor for changes
    while true; do
        sleep 0.1  # Check every 100ms
        local current_brightness=$(cat "$BACKLIGHT_FILE")
        
        if [[ $current_brightness -ne $last_brightness ]]; then
            show_notification "$current_brightness"
            last_brightness=$current_brightness
        fi
    done
}

# Handle start/stop commands
case "${1:-start}" in
    "start")
        if [[ -f "$PID_FILE" ]]; then
            local pid=$(cat "$PID_FILE")
            if kill -0 "$pid" 2>/dev/null; then
                echo "Monitor is already running (PID: $pid)"
                exit 0
            else
                rm -f "$PID_FILE"
            fi
        fi
        
        echo "Starting keyboard backlight monitor..."
        monitor_backlight &
        echo $! > "$PID_FILE"
        echo "Monitor started (PID: $(cat $PID_FILE))"
        ;;
    "stop")
        if [[ -f "$PID_FILE" ]]; then
            local pid=$(cat "$PID_FILE")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                rm -f "$PID_FILE"
                echo "Monitor stopped"
            else
                echo "Monitor is not running"
                rm -f "$PID_FILE"
            fi
        else
            echo "No PID file found"
        fi
        ;;
    *)
        echo "Usage: $0 [start|stop]"
        exit 1
        ;;
esac

