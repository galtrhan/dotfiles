#!/bin/bash
notify-send -u critical -t 5000 "sudo" "Password required"
rofi -dmenu -password -p "sudo password" -theme-str 'window {width: 420px; padding: 6px 12px; border: 2px solid; border-color: @border-color; background-color: rgba(32, 32, 32, 100%);} mainbox {children: [inputbar];} listview {enabled: false;} inputbar {padding: 0;}'
