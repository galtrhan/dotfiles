#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    exec "$SCRIPT_DIR/screen_capture.sh" stop
else
    SELECTED=$("$SCRIPT_DIR/qs-menu.sh" "Recording Audio" \
        "None (no audio)" \
        "System Audio (output)" \
        "Digital Microphone (internal)" \
        "Stereo Microphone (external)")

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
