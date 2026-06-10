#!/usr/bin/env bash

# Toggle active window between solo layout (75% x 70%, centered, floating) and tiled

LOCK="/tmp/toggle_solo_lock"

# Prevent key-repeat from firing multiple times
if [[ -f "${LOCK}" ]]; then
    exit 0
fi
touch "${LOCK}"
sleep 0.4
rm -f "${LOCK}"

activewindow=$(hyprctl activewindow -j)
addr=$(echo "${activewindow}" | jq -r '.address')
is_floating=$(echo "${activewindow}" | jq -r '.floating')

if [[ -z "${addr}" || "${addr}" == "null" ]]; then
    exit 1
fi

if [[ "${is_floating}" == "true" ]]; then
    hyprctl dispatch "hl.dsp.window.float({ action = \"toggle\", window = \"address:${addr}\" })" >/dev/null 2>&1
else
    monitor_info=$(hyprctl monitors -j | jq '.[] | select(.focused == true)')
    width=$(echo "${monitor_info}" | jq '.width')
    height=$(echo "${monitor_info}" | jq '.height')
    mon_x=$(echo "${monitor_info}" | jq '.x')
    mon_y=$(echo "${monitor_info}" | jq '.y')

    new_width=$((width * 75 / 100))
    new_height=$((height * 70 / 100))
    pos_x=$((mon_x + (width - new_width) / 2))
    pos_y=$((mon_y + (height - new_height) / 2))

    hyprctl dispatch "hl.dsp.window.float({ action = \"toggle\", window = \"address:${addr}\" })" >/dev/null 2>&1
    sleep 0.05
    hyprctl dispatch "hl.dsp.window.resize({ x = ${new_width}, y = ${new_height}, relative = false, window = \"address:${addr}\" })" >/dev/null 2>&1
    sleep 0.05
    hyprctl dispatch "hl.dsp.window.move({ x = ${pos_x}, y = ${pos_y}, relative = false, window = \"address:${addr}\" })" >/dev/null 2>&1
fi
