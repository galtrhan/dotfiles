#!/bin/bash

SCRIPT_DIR="$HOME/.config/hypr/scripts"

OPTIONS="None (no audio)\nSystem Audio (output)\nDigital Microphone (internal)\nStereo Microphone (external)"

SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Recording Audio" \
    -theme-str 'window {width: 500px;} mainbox {children: [ inputbar, listview ]; } listview {lines: 4; fixed-height: true; spacing: 2px;} element {padding: 8px; margin: 2px 0px;} element-text {vertical-align: 0.5;}')

case "$SELECTED" in
    "None (no audio)")
        exec "$SCRIPT_DIR/screen_capture.sh" toggle
        ;;
    "System Audio (output)")
        exec "$SCRIPT_DIR/screen_capture.sh" toggle --audio
        ;;
    "Digital Microphone (internal)")
        exec "$SCRIPT_DIR/screen_capture.sh" toggle --audio=alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source
        ;;
    "Stereo Microphone (external)")
        exec "$SCRIPT_DIR/screen_capture.sh" toggle --audio=alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic2__source
        ;;
    *)
        exit 1
        ;;
esac
