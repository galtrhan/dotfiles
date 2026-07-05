#!/bin/bash

# Usage: ./brightness.sh [get|up|down]
# get - Get current brightness
# up - Increase brightness
# down - Decrease brightness

STEP=10

# Get brightness
get_backlight() {
	brightnessctl -m | cut -d, -f4 | sed 's/%//'
}

# Notify
notify_user() {
	notify-send -a "Brightness" -u normal -t 3000 -h int:value:$CURRENT "Brightness : $CURRENT%"
}

# Change brightness
change_backlight() {
	local CURRENT_BRIGHTNESS
	local NEW_BRIGHTNESS
	
	CURRENT_BRIGHTNESS=$(get_backlight)
	
	# Calculate new brightness percentage
	if [[ "$1" == "+${STEP}%" ]]; then
		NEW_BRIGHTNESS=$((CURRENT_BRIGHTNESS + STEP))
	elif [[ "$1" == "-${STEP}%" ]]; then
		NEW_BRIGHTNESS=$((CURRENT_BRIGHTNESS - STEP))
	else
		echo "Invalid argument: $1"
		return 1
	fi

	# Ensure new brightness is within valid range
	if (( NEW_BRIGHTNESS < 0 )); then
		NEW_BRIGHTNESS=0
	elif (( NEW_BRIGHTNESS > 100 )); then
		NEW_BRIGHTNESS=100
	fi

	# Set the new brightness
	echo "Setting brightness to ${NEW_BRIGHTNESS}%"
	if brightnessctl set "${NEW_BRIGHTNESS}%"; then
		# Update CURRENT variable and notify
		CURRENT=$NEW_BRIGHTNESS
		notify_user
	else
		echo "Failed to set brightness"
		return 1
	fi
}

# Execute accordingly
case "$1" in
	"get")
		get_backlight
		;;
	"up"|"--inc")
		change_backlight "+${STEP}%"
		;;
	"down"|"--dec")
		change_backlight "-${STEP}%"
		;;
	*)
		get_backlight
		;;
esac
