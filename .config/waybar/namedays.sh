#!/bin/sh
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-date-format"

if [ "$1" = "--toggle" ]; then
    if [ -f "$STATE_FILE" ]; then
        rm -f "$STATE_FILE"
    else
        touch "$STATE_FILE"
    fi
    exit 0
fi

names=$(lnd)

if [ -f "$STATE_FILE" ]; then
    day=$(date "+%-d")
    case $day in
        1|21|31) suffix="st" ;;
        2|22) suffix="nd" ;;
        3|23) suffix="rd" ;;
        *) suffix="th" ;;
    esac
    text=$(date "+%A %B ${day}${suffix} %Y")
else
    text=$(date "+%H:%M   %Y.%m.%d")
fi

alt=$(date "+%Y.%m.%d")
printf '{"text":"%s","alt":"%s","tooltip":"%s","class":"namedays"}\n' "$text" "$alt" "$names"
