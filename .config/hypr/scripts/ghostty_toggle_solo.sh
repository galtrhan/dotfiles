#!/usr/bin/env bash

# Toggle ghostty between solo layout (75% x 80% centered, floating) and tiled

LOCK="/tmp/ghostty_solo_lock"

# Prevent key-repeat from firing multiple times
if [[ -f "${LOCK}" ]]; then
    exit 0
fi
touch "${LOCK}"
sleep 0.4
rm -f "${LOCK}"

# Get active window info
activewindow=$(hyprctl activewindow -j)
addr=$(echo "${activewindow}" | jq -r '.address')
is_floating=$(echo "${activewindow}" | jq -r '.floating')

if [[ -z "${addr}" || "${addr}" == "null" ]]; then
    exit 1
fi

if [[ "${is_floating}" == "true" ]]; then
    # Already in solo/floating mode — return to tiled
    hyprctl dispatch togglefloating "address:${addr}"
else
    # Enter solo layout — float, resize, center
    monitor_info=$(hyprctl monitors -j | jq '.[] | select(.focused == true)')
    width=$(echo "${monitor_info}" | jq '.width')
    height=$(echo "${monitor_info}" | jq '.height')
    mon_x=$(echo "${monitor_info}" | jq '.x')
    mon_y=$(echo "${monitor_info}" | jq '.y')

    new_width=$((width * 75 / 100))
    new_height=$((height * 70 / 100))
    pos_x=$(( mon_x + (width - new_width) / 2 ))
    pos_y=$(( mon_y + (height - new_height) / 2 ))

    hyprctl dispatch togglefloating "address:${addr}"
    sleep 0.05
    hyprctl dispatch resizewindowpixel "exact ${new_width} ${new_height},address:${addr}"
    sleep 0.05
    hyprctl dispatch movewindowpixel "exact ${pos_x} ${pos_y},address:${addr}"
fi
