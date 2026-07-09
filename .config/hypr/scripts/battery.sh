#!/bin/bash

BATTERY="/sys/class/power_supply/BAT0"
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/battery-notify-state"

THRESHOLDS=(20 15 10 5)

load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
    else
        NOTIFIED=""
    fi
}

save_state() {
    echo "NOTIFIED=\"$NOTIFIED\"" > "$STATE_FILE"
}

is_notified() {
    local level="$1"
    [[ " $NOTIFIED " =~ " $level " ]]
}

mark_notified() {
    local level="$1"
    if [[ -z "$NOTIFIED" ]]; then
        NOTIFIED="$level"
    else
        NOTIFIED="$NOTIFIED $level"
    fi
}

notify() {
    local urgency="$1"
    local title="$2"
    local message="$3"
    local value="$4"
    if [[ -n "$value" ]]; then
        notify-send -a "Battery" -u "$urgency" -t 5000 -h int:value:"$value" "$title" "$message"
    else
        notify-send -a "Battery" -u "$urgency" -t 5000 "$title" "$message"
    fi
    return $?
}

main() {
    load_state

    if [[ ! -r "$BATTERY/capacity" ]] || [[ ! -r "$BATTERY/status" ]]; then
        exit 1
    fi

    local capacity status
    capacity=$(< "$BATTERY/capacity")
    status=$(< "$BATTERY/status")

    if [[ "$status" != "Discharging" ]]; then
        NOTIFIED=""
        save_state
        exit 0
    fi

    for threshold in "${THRESHOLDS[@]}"; do
        if (( capacity <= threshold )) && ! is_notified "$threshold"; then
            if (( threshold <= 5 )); then
                notify "critical" "REACTOR CRITICAL" "POWER CORE AT ${capacity}% — IMMEDIATE SHUTDOWN REQUIRED" "$capacity"
            elif (( threshold <= 10 )); then
                notify "critical" "Battery Critical" "${capacity}% — plug in now!" "$capacity"
            elif (( threshold == 15 )); then
                notify "critical" "Battery Low" "${capacity}% — find a charger." "$capacity"
            else
                notify "normal" "Battery Warning" "${capacity}% remaining." "$capacity"
            fi
            if [[ $? -eq 0 ]]; then
                mark_notified "$threshold"
            fi
        fi
    done

    save_state
}

main
