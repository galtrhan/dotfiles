#!/bin/bash
notify-send -u critical -t 5000 "sudo" "Password required"
rofi -dmenu -password -p "sudo password" -theme ~/.config/rofi/themes/sudo.rasi 2>/dev/null || \
rofi -dmenu -password -p "sudo password"
