#!/bin/bash

# QuickShell IP widget: MAC status and randomization via macchanger.

set -euo pipefail

readonly HISTORY_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/mac-history"
readonly MAX_HISTORY=3
readonly SUDO_ASKPASS="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/sudo_askpass.sh"

get_interface() {
	ip -o route show to default 2>/dev/null | awk '{print $5; exit}'
}

get_mac() {
	local iface="${1:-$(get_interface)}"
	[[ -n "$iface" ]] || return 1
	ip link show "$iface" 2>/dev/null | awk '/link\/ether/ {print $2; exit}'
}

read_history() {
	[[ -f "$HISTORY_FILE" ]] || return 0
	cat "$HISTORY_FILE"
}

push_history() {
	local mac="$1"
	local -a history=()
	local line

	while IFS= read -r line; do
		[[ -n "$line" && "$line" != "$mac" ]] && history+=("$line")
	done < <(read_history)

	history=("$mac" "${history[@]}")
	history=("${history[@]:0:$MAX_HISTORY}")

	mkdir -p "$(dirname "$HISTORY_FILE")"
	if ((${#history[@]} == 0)); then
		: >"$HISTORY_FILE"
	else
		printf '%s\n' "${history[@]}" >"$HISTORY_FILE"
	fi
}

json_escape() {
	local value="$1"
	value=${value//\\/\\\\}
	value=${value//\"/\\\"}
	printf '%s' "$value"
}

status_json() {
	local iface mac
	local -a history=()
	local line

	iface="$(get_interface || true)"
	mac=""
	[[ -n "$iface" ]] && mac="$(get_mac "$iface" || true)"

	while IFS= read -r line; do
		[[ -n "$line" ]] && history+=("$line")
	done < <(read_history)

	printf '{"interface":"%s","mac":"%s","history":[' \
		"$(json_escape "${iface:-}")" \
		"$(json_escape "${mac:-}")"

	local index
	for index in "${!history[@]}"; do
		[[ "$index" -gt 0 ]] && printf ','
		printf '"%s"' "$(json_escape "${history[$index]}")"
	done
	printf ']}\n'
}

notify_mac_changed() {
	local mac="$1"

	printf '%s' "$mac" | wl-copy
	notify-send -a "Network" -u normal -t 3000 "MAC address changed" "$mac"
}

randomize_mac() {
	local iface mac new_mac

	iface="$(get_interface || true)"
	[[ -n "$iface" ]] || {
		printf '{"error":"no default network interface"}\n' >&2
		exit 1
	}

	mac="$(get_mac "$iface" || true)"
	[[ -n "$mac" ]] || {
		printf '{"error":"no MAC address on %s"}\n' "$iface" >&2
		exit 1
	}

	push_history "$mac"

	export SUDO_ASKPASS
	sudo -A ip link set "$iface" down
	sudo -A macchanger -r "$iface"
	sudo -A ip link set "$iface" up

	new_mac="$(get_mac "$iface" || true)"
	[[ -n "$new_mac" ]] && notify_mac_changed "$new_mac"

	status_json
}

case "${1:-status}" in
status)
	status_json
	;;
randomize)
	randomize_mac
	;;
*)
	printf 'Usage: %s [status|randomize]\n' "$(basename "$0")" >&2
	exit 1
	;;
esac
