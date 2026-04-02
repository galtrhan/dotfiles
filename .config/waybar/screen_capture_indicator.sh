#!/usr/bin/env bash
# Return JSON for waybar screen capture indicator

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="${RUNTIME_DIR}/screen_capture.pid"

if [[ -f "${PID_FILE}" ]]; then
    pid=$(cat "${PID_FILE}" 2>/dev/null)
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
        echo '{"text": "● REC", "alt": "recording", "class": "recording"}'
        exit 0
    fi
fi

echo '{"text": "", "alt": "idle", "class": "idle"}'
