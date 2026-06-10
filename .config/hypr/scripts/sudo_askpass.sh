#!/bin/bash
notify-send -u critical -t 5000 "sudo" "Password required"

PREV_WS=$(hyprctl activeworkspace -j | jq -r '.name')
PREV_SPECIAL=$(
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .specialWorkspace.name' | head -n1
)
[[ "$PREV_SPECIAL" == "null" ]] && PREV_SPECIAL=""

cleanup() {
    if hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name == "special:sudo")' >/dev/null; then
        hyprctl dispatch 'hl.dsp.workspace.toggle_special("sudo")' >/dev/null 2>&1 || true
    fi

    if [[ -n "$PREV_SPECIAL" && "$PREV_SPECIAL" != "special:sudo" ]]; then
        local special_name="${PREV_SPECIAL#special:}"
        hyprctl dispatch "hl.dsp.workspace.toggle_special(\"${special_name}\")" >/dev/null 2>&1 || true
    elif [[ -n "$PREV_WS" ]]; then
        hyprctl dispatch "hl.dsp.focus({ workspace = \"${PREV_WS}\" })" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT INT TERM

hyprctl dispatch 'hl.dsp.workspace.toggle_special("sudo")' >/dev/null 2>&1

PASSWORD=$(
    rofi -normal-window -dmenu -password -p "sudo password" -no-lazy-grab -steal-focus \
        -theme-str 'window {width: 420px; padding: 1px; border: 0; border-radius: 4px; background-image: linear-gradient(45deg, rgba(51, 204, 255, 93%), rgba(0, 255, 153, 93%));} mainbox {children: [inputbar]; padding: 5px 11px; border-radius: 3px; background-color: rgba(32, 32, 32, 100%);} listview {enabled: false;} inputbar {padding: 0;}'
)

echo "$PASSWORD"
