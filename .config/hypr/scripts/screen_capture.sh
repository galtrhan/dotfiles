#!/usr/bin/env bash
#
# screen_capture.sh
#
# Usage:
#   screen_capture.sh start   - start a wf-recorder recording (select area via slurp)
#   screen_capture.sh stop    - stop the currently running recording
#   screen_capture.sh status  - show recording status
#   screen_capture.sh help    - show this help
#
# Behavior:
# - Checks for required utilities (wf-recorder, slurp). Notifies the user if missing.
# - Uses notify-send when available for desktop notifications.
# - Stores runtime state (PID & output path) in $XDG_RUNTIME_DIR or /tmp.
# - On stop, attempts to copy resulting video to the Wayland clipboard via wl-copy (if available).
#   Your Hyprland config already runs wl-paste --watch cliphist store, so copying with wl-copy
#   should make cliphist pick it up automatically (if cliphist is running).
#
set -uo pipefail

# Configuration
SAVE_DIR="${HOME}/Videos/Capture"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="${RUNTIME_DIR}/screen_capture.pid"
OUT_FILE_FILE="${RUNTIME_DIR}/screen_capture.out"   # contains last output filename
LOG_PREFIX="[screen_capture]"

# Commands we'll reference
CMD_WF="wf-recorder"
CMD_SLURP="slurp"
CMD_NOTIFY="notify-send"
CMD_WL_COPY="wl-copy"
CMD_CLIPHIST="cliphist"

# Helpers
notify() {
    local title="$1"; shift
    local body="$*"
    if command -v "${CMD_NOTIFY}" >/dev/null 2>&1; then
        "${CMD_NOTIFY}" "${title}" "${body}"
    else
        # Fallback to echo if no notification binary available
        printf '%s %s: %s\n' "${LOG_PREFIX}" "${title}" "${body}" >&2
    fi
}

exists() {
    command -v "$1" >/dev/null 2>&1
}

usage() {
    cat <<EOF
Usage: $(basename "$0") <start|stop|toggle|status|help> [options]

Commands:
  start   - Start recording (select area with slurp)
  stop    - Stop recording and optionally copy file to clipboard
  toggle  - Toggle recording (start if inactive, stop if active)
  status  - Show whether a recording is active
  help    - Show this help

Options:
  -a, --audio  - Enable audio capture (only with 'start' and 'toggle')
EOF
}

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

required_for_start_ok() {
    local missing=()
    for cmd in "${CMD_WF}" "${CMD_SLURP}"; do
        if ! exists "${cmd}"; then
            missing+=("${cmd}")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        notify "Screen capture — missing tools" "Required tools missing: ${missing[*]}. Please install them."
        return 1
    fi
    return 0
}

start_recording() {
    local audio_flag=""

    if is_recording; then
        notify "Screen capture" "Recording already in progress (PID $(cat "${PID_FILE}")). Use 'stop' first."
        return 1
    fi

    if ! required_for_start_ok; then
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "${SAVE_DIR}" || {
        notify "Screen capture" "Failed to create directory ${SAVE_DIR}"
        return 1
    }

    # Choose output filename
    TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
    OUTFILE="${SAVE_DIR}/${TIMESTAMP}.mp4"

    # Ask slurp for a region; if slurp fails or is cancelled, abort
    GEOM="$(slurp)"
    if [[ -z "${GEOM}" ]]; then
        notify "Screen capture" "Selection cancelled — not starting recording."
        return 1
    fi

    # Add audio flag if requested
    if [[ "${AUDIO_ENABLED:-false}" == "true" ]]; then
        audio_flag="-a"
    fi

    # Start wf-recorder in background, store PID and output path
    # Use setsid so it keeps running independently of the shell if needed
    setsid "${CMD_WF}" -g "${GEOM}" ${audio_flag} -f "${OUTFILE}" >/dev/null 2>&1 &
    WF_PID=$!

    # Save state
    printf '%s' "${WF_PID}" > "${PID_FILE}"
    printf '%s' "${OUTFILE}" > "${OUT_FILE_FILE}"

    local audio_status=""
    if [[ "${AUDIO_ENABLED:-false}" == "true" ]]; then
        audio_status=" (with audio)"
    fi
    notify "Screen capture started" "Recording to: ${OUTFILE}${audio_status}"
    echo "${WF_PID}"
}

notify_with_thumbnail() {
    local title="$1"; shift
    local body="$*"
    local thumb_path=""

    # Try to generate thumbnail if ffmpeg is available
    if exists "ffmpeg" && [[ -f "${OUTFILE}" ]]; then
        thumb_path="$(mktemp --suffix=.png 2>/dev/null || mktemp /tmp/screen_capture_thumb.XXXXXX.png)"
        if ffmpeg -y -i "${OUTFILE}" -vf "scale=iw/3:ih/3" -vframes 1 -f image2 "${thumb_path}" >/dev/null 2>&1; then
            # notify-send supports -i flag for image notifications
            if command -v "${CMD_NOTIFY}" >/dev/null 2>&1; then
                "${CMD_NOTIFY}" -i "${thumb_path}" "${title}" "${body}"
            else
                printf '%s %s: %s\n' "${LOG_PREFIX}" "${title}" "${body}" >&2
            fi
            rm -f "${thumb_path}" 2>/dev/null || true
            return 0
        else
            rm -f "${thumb_path}" 2>/dev/null || true
        fi
    fi

    # Fallback to regular notification
    notify "${title}" "${body}"
}

stop_recording() {
    if ! is_recording; then
        notify "Screen capture" "No active recording found."
        return 1
    fi

    PID="$(cat "${PID_FILE}" 2>/dev/null || echo "")"
    OUTFILE="$(cat "${OUT_FILE_FILE}" 2>/dev/null || echo "")"

    if [[ -z "${PID}" ]]; then
        notify "Screen capture" "Record PID file corrupt or missing."
        rm -f "${PID_FILE}" "${OUT_FILE_FILE}" 2>/dev/null || true
        return 1
    fi

    # Prefer a graceful SIGINT so wf-recorder finalizes file cleanly
    kill -INT "${PID}" >/dev/null 2>&1 || {
        # fallback to TERM
        kill -TERM "${PID}" >/dev/null 2>&1 || true
    }

    # Wait for process to exit with timeout
    local waited=0
    local timeout=8
    while kill -0 "${PID}" >/dev/null 2>&1; do
        sleep 0.5
        waited=$((waited + 1))
        if (( waited*1 >= timeout*2 )); then
            # give up and force kill
            kill -KILL "${PID}" >/dev/null 2>&1 || true
            break
        fi
    done

    # Clean up PID file
    rm -f "${PID_FILE}"

    # Verify output file exists
    if [[ -z "${OUTFILE}" ]]; then
        notify "Screen capture" "Recording stopped, but output path unknown."
        rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
        return 0
    fi

    if [[ ! -f "${OUTFILE}" ]]; then
        notify "Screen capture" "Recording stopped but file not found: ${OUTFILE}"
        rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
        return 1
    fi

    # Optionally copy to clipboard if wl-copy is available
    if exists "${CMD_WL_COPY}"; then
        # Try several wl-copy variants because different wl-clipboard versions accept different flags
        copy_ok=1
        # 1) try explicit mime-type flag commonly supported
        if "${CMD_WL_COPY}" --type=video/mp4 < "${OUTFILE}" >/dev/null 2>&1; then
            copy_ok=0
            copy_method="wl-copy --type=video/mp4"
        # 2) try without equals (some implementations parse it differently)
        elif "${CMD_WL_COPY}" --type video/mp4 < "${OUTFILE}" >/dev/null 2>&1; then
            copy_ok=0
            copy_method="wl-copy --type video/mp4"
        # 3) try plain wl-copy (some will infer type)
        elif "${CMD_WL_COPY}" < "${OUTFILE}" >/dev/null 2>&1; then
            copy_ok=0
            copy_method="wl-copy < file"
        fi

        if [[ "${copy_ok}" -eq 0 ]]; then
            # If cliphist is installed and your hypr config runs wl-paste --watch cliphist store,
            # that will automatically store the copied clip.
            if exists "${CMD_CLIPHIST}"; then
                notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE} — copied to clipboard using: ${copy_method} (cliphist should store it)."
            else
                notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE} — copied to clipboard using: ${copy_method}."
            fi
            rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
            return 0
        fi

        # If direct video copy failed, try copying the file path as text so you can paste it
        if printf '%s' "${OUTFILE}" | "${CMD_WL_COPY}" >/dev/null 2>&1; then
            notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE} — file path copied to clipboard (you can paste the path)."
            rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
            return 0
        fi

        # As a nicer fallback, if ffmpeg exists try to generate a thumbnail and copy that image
        if exists "ffmpeg"; then
            thumb="$(mktemp --suffix=.png 2>/dev/null || mktemp /tmp/screen_capture_thumb.XXXXXX.png)"
            # create a small thumbnail (1 frame) from the video
            if ffmpeg -y -i "${OUTFILE}" -vf "scale=iw/3:ih/3" -vframes 1 -f image2 "${thumb}" >/dev/null 2>&1; then
                # try to copy thumbnail as image/png
                if "${CMD_WL_COPY}" --type=image/png < "${thumb}" >/dev/null 2>&1 || "${CMD_WL_COPY}" < "${thumb}" >/dev/null 2>&1; then
                    notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE} — thumbnail copied to clipboard."
                    rm -f "${thumb}" 2>/dev/null || true
                    rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
                    return 0
                else
                    notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE} — thumbnail generation succeeded but copying thumbnail failed."
                    rm -f "${thumb}" 2>/dev/null || true
                    rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
                    return 0
                fi
            else
                rm -f "${thumb}" 2>/dev/null || true
            fi
        fi

        # Last-resort: notify user that copying to clipboard failed but file saved
        notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE} — failed to copy to clipboard. You can find the file in your Videos folder."
        rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
        return 0
    else
        # wl-copy not installed: just notify with file location and offer copying path if wl-copy missing
        if exists "${CMD_CLIPHIST}"; then
            notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE}. cliphist is installed but wl-copy is missing; consider installing wl-clipboard (wl-copy) to copy files to clipboard automatically."
        else
            notify_with_thumbnail "Screen capture finished" "Saved: ${OUTFILE}."
        fi
        rm -f "${OUT_FILE_FILE}" 2>/dev/null || true
        return 0
    fi
}

status() {
    local silent="${1:-false}"
    if is_recording; then
        if [[ "${silent}" != "true" ]]; then
            PID="$(cat "${PID_FILE}" 2>/dev/null || echo "")"
            OUTFILE="$(cat "${OUT_FILE_FILE}" 2>/dev/null || echo "")"
            notify "Screen capture status" "Recording active (PID ${PID}). Output: ${OUTFILE}"
        fi
        return 0
    else
        if [[ "${silent}" != "true" ]]; then
            notify "Screen capture status" "No active recording."
        fi
        return 1
    fi
}

toggle() {
    if is_recording; then
        stop_recording
    else
        start_recording
    fi
}

# Main
if [[ $# -lt 1 ]]; then
    usage
    exit 2
fi

cmd="$1"; shift
AUDIO_ENABLED=false

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--audio)
            AUDIO_ENABLED=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 2
            ;;
    esac
done

case "${cmd}" in
    start)
        start_recording
        exit $?
        ;;
    stop)
        stop_recording
        exit $?
        ;;
    toggle)
        toggle
        exit $?
        ;;
    status)
        # Support --silent flag for waybar integration
        silent_mode="false"
        if [[ "$1" == "--silent" ]]; then
            silent_mode="true"
        fi
        status "${silent_mode}"
        exit $?
        ;;
    help|--help|-h)
        usage
        exit 0
        ;;
    *)
        echo "Unknown command: ${cmd}" >&2
        usage
        exit 2
        ;;
esac
