#!/bin/bash

# Usage: ./power.sh [lock]
# lock - Lock the screen immediately

# Handle direct lock argument
if [ "$1" = "lock" ]; then
    pidof hyprlock || hyprlock --immediate
    exit 0
fi

# Define the options
OPTIONS="Lock\nLogout\nSuspend\nReboot\nShutdown"

# Show the menu using rofi and get the selected option
SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Power Menu" -theme-str 'window {width: 400px;} mainbox {children: [ inputbar, listview ]; } listview {lines: 5; fixed-height: true; spacing: 2px;} element {padding: 8px; margin: 2px 0px;} element-text {vertical-align: 0.5;}')

# Perform the selected action
case "$SELECTED" in
    Lock)
        pidof hyprlock || hyprlock ;;
    Logout)
        hyprctl dispatch exit ;;
    Suspend)
        systemctl suspend ;;
    Reboot)
        systemctl reboot ;;
    Shutdown)
        systemctl poweroff ;;
    *)
        echo "No valid option selected."
        exit 1 ;;
esac
