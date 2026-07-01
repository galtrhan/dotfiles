#!/bin/bash

STEP=5
MUTE_LED_PATH="/sys/class/leds/platform::mute/brightness"
MIC_LED_PATH="/sys/class/leds/platform::micmute/brightness"

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

# Check if mic is muted
is_mic_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "MUTED"
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

# Toggle Mic
toggle_mic() {
    if is_mic_muted; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 && notify-send -a "Volume" -u normal -t 3000 "Microphone Switched ON"
    else
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 && notify-send -a "Volume" -u critical -t 3000 "Microphone Switched OFF"
    fi
    sync_mic_led
}

# Get Microphone Volume
get_mic_volume() {
    volume=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print $2 * 100}')
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
    if is_mic_muted; then
        toggle_mic
    else
        current_volume=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print $2 * 100}')
        current_volume=${current_volume%.*}
        if [[ "$current_volume" -lt 95 ]]; then
            wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ && notify_mic_user
        else
            # Set to exactly 100% if we're close to the limit
            wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 100% && notify_mic_user
        fi
    fi
}

# Decrease MIC Volume
dec_mic_volume() {
    if is_mic_muted; then
        toggle_mic
    else
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%- && notify_mic_user
    fi
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
else
    get_volume
fi
