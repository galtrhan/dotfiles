#!/bin/bash

STEP=5
MUTE_LED_PATH="/sys/class/leds/platform::mute/brightness"
MIC_LED_PATH="/sys/class/leds/platform::micmute/brightness"
SELECTED_MIC_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-selected-mic"

# Get Volume
get_volume() {
    volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "${volume%.*}"
    fi
}

# Check if muted
is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"
}

# List PipeWire audio source node IDs (excludes monitor/speaker nodes)
list_audio_sources() {
    wpctl status 2>/dev/null | awk '
        /Sources:/ { in_sources=1; next }
        in_sources && /^ ├─ Filters:/ { exit }
        in_sources && /^ └─ Streams:/ { exit }
        in_sources && /^ │/ {
            line = $0
            sub(/^ │[\* ]*/, "", line)
            id = line
            sub(/\..*/, "", id)
            if (id ~ /^[0-9]+$/) print id
        }'
}

# List sources as "id|nickname", marking the currently selected mic with a trailing "*"
list_audio_sources_named() {
    local selected_id
    selected_id=$(selected_source_id)
    local source_id
    local name

    while read -r source_id; do
        name=$(wpctl inspect "$source_id" 2>/dev/null | awk -F'"' '/node.nick/ {print $2; exit}')
        if [[ -z "$name" ]]; then
            name=$(wpctl inspect "$source_id" 2>/dev/null | awk -F'"' '/node.description/ {print $2; exit}')
        fi
        [[ -z "$name" ]] && name="Mic $source_id"
        if [[ "$source_id" == "$selected_id" ]]; then
            echo "$source_id|$name*"
        else
            echo "$source_id|$name"
        fi
    done <<< "$(list_audio_sources)"
}

# ID of the current default audio source, or empty if none
default_source_id() {
    wpctl status 2>/dev/null | awk '
        /Sources:/ { in_sources=1; next }
        in_sources && /^ ├─ Filters:/ { exit }
        in_sources && /^ └─ Streams:/ { exit }
        in_sources && /^ │/ {
            if ($0 ~ /\*/) {
                line = $0
                sub(/^ │[\* ]*/, "", line)
                id = line
                sub(/\..*/, "", id)
                if (id ~ /^[0-9]+$/) { print id; exit }
            }
        }'
}

# ID of the user-selected mic, falling back to the default source
selected_source_id() {
    if [[ -s "$SELECTED_MIC_FILE" ]]; then
        cat "$SELECTED_MIC_FILE"
    else
        default_source_id
    fi
}

# Set the selected mic (persisted) and make it the default source
set_selected_source() {
    local id="$1"
    if [[ -z "$id" ]]; then
        return 1
    fi
    mkdir -p "$(dirname "$SELECTED_MIC_FILE")"
    printf '%s' "$id" > "$SELECTED_MIC_FILE"
    wpctl set-default "$id"
}

# Mic is muted only when every capture source is muted
is_mic_muted() {
    local source_id
    local sources
    sources=$(list_audio_sources)

    if [[ -z "$sources" ]]; then
        wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "MUTED"
        return
    fi

    while read -r source_id; do
        if ! wpctl get-volume "$source_id" 2>/dev/null | grep -q "MUTED"; then
            return 1
        fi
    done <<< "$sources"
}

set_all_mic_mute() {
    local mute_state="$1"
    local source_id
    local sources
    local changed=false
    sources=$(list_audio_sources)

    if [[ -z "$sources" ]]; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ "$mute_state"
        return
    fi

    while read -r source_id; do
        if wpctl set-mute "$source_id" "$mute_state" 2>/dev/null; then
            changed=true
        fi
    done <<< "$sources"

    [[ "$changed" == true ]]
}

# Write LED state only when writable
set_led_state() {
    led_path="$1"
    led_state="$2"

    if [[ -w "$led_path" ]]; then
        printf "%s" "$led_state" > "$led_path"
    fi
}

# Sync mute LED with actual state
sync_mute_led() {
    if is_muted; then
        set_led_state "$MUTE_LED_PATH" 1
    else
        set_led_state "$MUTE_LED_PATH" 0
    fi
}

# Sync mic mute LED with actual state
sync_mic_led() {
    if is_mic_muted; then
        set_led_state "$MIC_LED_PATH" 1
    else
        set_led_state "$MIC_LED_PATH" 0
    fi
}

# Notify
notify_user() {
    volume=$(get_volume)
    if [[ "$volume" == "Muted" ]]; then
        notify-send -a "Volume" -u critical -t 3000 -h int:value:0 "Volume: Muted"
    else
        notify-send -a "Volume" -u normal -t 3000 -h int:value:$volume "Volume: $volume%"
    fi
}

# Increase Volume
inc_volume() {
    if is_muted; then
        toggle_mute
    else
        current_volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')
        current_volume=${current_volume%.*}
        if [[ "$current_volume" -lt 95 ]]; then
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify_user
        else
            # Set to exactly 100% if we're close to the limit
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 100% && notify_user
        fi
    fi
}

# Decrease Volume
dec_volume() {
    if is_muted; then
        toggle_mute
    else
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify_user
    fi
}

# Toggle Mute
toggle_mute() {
    if is_muted; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && notify-send -a "Volume" -u normal -t 3000 -h int:value:$(get_volume) "Volume Switched ON"
    else
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 && notify-send -a "Volume" -u critical -t 3000 -h int:value:0 "Volume Switched OFF"
    fi
    sync_mute_led
}

# Toggle Mic (mute/unmute ALL mics)
toggle_mic() {
    if is_mic_muted; then
        set_all_mic_mute 0 && notify-send -a "Volume" -u normal -t 3000 "Microphone Switched ON"
    else
        set_all_mic_mute 1 && notify-send -a "Volume" -u critical -t 3000 "Microphone Switched OFF"
    fi
    sync_mic_led
}

# Get Microphone Volume
get_mic_volume() {
    local mic_id
    mic_id=$(selected_source_id)
    if wpctl get-volume "$mic_id" 2>/dev/null | grep -q "MUTED"; then
        echo "Muted"
        return
    fi
    volume=$(wpctl get-volume "$mic_id" 2>/dev/null | awk '{print $2 * 100}')
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "${volume%.*}"
    fi
}

# Notify for Microphone
notify_mic_user() {
    volume=$(get_mic_volume)
    if [[ "$volume" == "Muted" ]]; then
        notify-send -a "Volume" -u critical -t 3000 -h int:value:0 "Mic-Level: Muted"
    else
        notify-send -a "Volume" -u normal -t 3000 -h int:value:$volume "Mic-Level: $volume%"
    fi
}

# Increase MIC Volume
inc_mic_volume() {
    local mic_id
    mic_id=$(selected_source_id)
    if wpctl get-volume "$mic_id" 2>/dev/null | grep -q "MUTED"; then
        wpctl set-mute "$mic_id" 0
    fi
    current_volume=$(wpctl get-volume "$mic_id" | awk '{print $2 * 100}')
    current_volume=${current_volume%.*}
    if [[ "$current_volume" -lt 95 ]]; then
        wpctl set-volume "$mic_id" 5%+ && notify_mic_user
    else
        # Set to exactly 100% if we're close to the limit
        wpctl set-volume "$mic_id" 100% && notify_mic_user
    fi
}

# Decrease MIC Volume
dec_mic_volume() {
    local mic_id
    mic_id=$(selected_source_id)
    if wpctl get-volume "$mic_id" 2>/dev/null | grep -q "MUTED"; then
        wpctl set-mute "$mic_id" 0
    fi
    wpctl set-volume "$mic_id" 5%- && notify_mic_user
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
    get_volume
elif [[ "$1" == "--inc" ]]; then
    inc_volume
elif [[ "$1" == "--dec" ]]; then
    dec_volume
elif [[ "$1" == "--toggle" ]]; then
    toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
    toggle_mic
elif [[ "$1" == "--mic-inc" ]]; then
    inc_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
    dec_mic_volume
elif [[ "$1" == "--mic-list" ]]; then
    list_audio_sources_named
elif [[ "$1" == "--mic-select" ]]; then
    set_selected_source "$2"
elif [[ "$1" == "--mic-selected" ]]; then
    selected_source_id
else
    get_volume
fi
