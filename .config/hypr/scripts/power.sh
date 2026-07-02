#!/bin/bash

# Usage: ./power.sh [lock]
# lock - Lock the screen immediately

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$1" = "lock" ]]; then
    pidof hyprlock || hyprlock --immediate
    exit 0
fi

SELECTED=$("$SCRIPT_DIR/qs-menu.sh" --compact "Power Menu" \
    "Lock" "Logout" "Suspend" "Reboot" "Shutdown")

case "$SELECTED" in
    Lock)
        pidof hyprlock || hyprlock ;;
    Logout)
        # hyprctl dispatch exit blocks when run synchronously from a script
        # until keyboard input (hyprwm/Hyprland#4793). Detach so logout works.
        (
            hyprctl dispatch exit || true
            sleep 2
            if pgrep -x Hyprland >/dev/null; then
                killall Hyprland 2>/dev/null || true
            fi
        ) >/dev/null 2>&1 &
        ;;
    Suspend)
        systemctl suspend ;;
    Reboot)
        systemctl reboot ;;
    Shutdown)
        systemctl poweroff ;;
    *)
        exit 1 ;;
esac
