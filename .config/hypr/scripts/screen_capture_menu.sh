#!/bin/bash

SCRIPT_DIR="$HOME/.config/hypr/scripts"
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/screen_capture.pid"

is_recording() {
    if [[ -f "${PID_FILE}" ]]; then
        local pid
        pid="$(cat "${PID_FILE}" 2>/dev/null || echo "")"
        if [[ -n "${pid}" ]] && kill -0 "${pid}" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

if is_recording; then
    SELECTED=$(echo -e "Stop recording" | rofi -dmenu -i -p "Recording active" \
        -theme-str 'window {width: 500px;} mainbox {children: [ inputbar, listview ]; } listview {lines: 1; fixed-height: true; spacing: 2px;} element {padding: 8px; margin: 2px 0px;} element-text {vertical-align: 0.5;}')
    case "$SELECTED" in
        "Stop recording")
            exec "$SCRIPT_DIR/screen_capture.sh" stop
            ;;
        *)
            exit 1
            ;;
    esac
else
    OPTIONS="None (no audio)\nSystem Audio (output)\nDigital Microphone (internal)\nStereo Microphone (external)"

    SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Recording Audio" \
        -theme-str 'window {width: 500px;} mainbox {children: [ inputbar, listview ]; } listview {lines: 4; fixed-height: true; spacing: 2px;} element {padding: 8px; margin: 2px 0px;} element-text {vertical-align: 0.5;}')

    case "$SELECTED" in
        "None (no audio)")
            exec "$SCRIPT_DIR/screen_capture.sh" toggle
            ;;
        "System Audio (output)")
            MONITOR_SOURCE="$(pactl get-default-sink 2>/dev/null).monitor"
            if [[ -z "${MONITOR_SOURCE}" ]] || [[ "${MONITOR_SOURCE}" == ".monitor" ]]; then
                notify-send "Screen capture" "Could not detect default audio sink monitor."
                exit 1
            fi
            exec "$SCRIPT_DIR/screen_capture.sh" toggle --audio="${MONITOR_SOURCE}"
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
fi
