#!/bin/bash

# QuickShell dev server widget: list npm run dev processes and listening ports.

set -euo pipefail

collect_descendants() {
	local pid="$1"
	echo "$pid"
	local child
	for child in $(pgrep -P "$pid" 2>/dev/null || true); do
		collect_descendants "$child"
	done
}

short_path() {
	local cwd="$1"
	local parent
	parent="$(basename "$(dirname "$cwd")")"
	echo "${parent}/$(basename "$cwd")"
}

port_from_addr() {
	local addr="$1"
	addr="${addr##*:}"
	addr="${addr%%]*}"
	echo "$addr"
}

kill_server() {
	local pid="$1"
	[[ "$pid" =~ ^[0-9]+$ ]] || return 1
	[[ -d "/proc/$pid" ]] || return 0

	local pgid
	pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')
	if [[ -n "$pgid" ]]; then
		kill -TERM -- "-$pgid" 2>/dev/null || true
	fi

	sleep 0.2
	while IFS= read -r p; do
		kill -KILL "$p" 2>/dev/null || true
	done < <(collect_descendants "$pid")
}

if [[ "${1:-}" == "kill" ]]; then
	kill_server "${2:-}"
	exit 0
fi

declare -A pid_ports

while IFS= read -r line; do
	[[ "$line" == LISTEN* ]] || continue

	local_addr="$(awk '{print $4}' <<<"$line")"
	port="$(port_from_addr "$local_addr")"
	[[ "$port" =~ ^[0-9]+$ ]] || continue

	rest="${line#*users:(}"
	while [[ "$rest" =~ pid=([0-9]+) ]]; do
		pid="${BASH_REMATCH[1]}"
		rest="${rest#*pid=${pid}}"
		if [[ -z "${pid_ports[$pid]:-}" ]]; then
			pid_ports[$pid]="$port"
		elif [[ "${pid_ports[$pid]}" != *",$port"* && "${pid_ports[$pid]}" != "$port" ]]; then
			pid_ports[$pid]="${pid_ports[$pid]},$port"
		fi
	done
done < <(ss -tlnp 2>/dev/null || true)

while IFS= read -r line; do
	[[ -n "$line" ]] || continue
	pid="${line%% *}"
	args="${line#"$pid"}"
	args="${args# }"
	[[ "$args" == npm\ run\ dev* ]] || continue

	cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || echo "?")
	label=$(short_path "$cwd")

	all_ports=""
	while IFS= read -r p; do
		p_ports="${pid_ports[$p]:-}"
		[[ -n "$p_ports" ]] || continue
		if [[ -n "$all_ports" ]]; then
			all_ports="$all_ports,$p_ports"
		else
			all_ports="$p_ports"
		fi
	done < <(collect_descendants "$pid")

	if [[ -n "$all_ports" ]]; then
		sorted_ports=$(echo "$all_ports" | tr ',' '\n' | sort -nu | paste -sd, -)
	else
		sorted_ports=""
	fi

	echo "${label}|${sorted_ports}|${pid}"
done < <(ps ax -o pid=,args= 2>/dev/null | awk '$2 == "npm" && $3 == "run" && $4 == "dev"')

# Also detect any process listening on port 4321 (e.g. Astro dev server).
declare -A captured_pids
while IFS= read -r line; do
	pid="$(awk '{print $1}' <<<"$line")"
	captured_pids["$pid"]=1
done < <(ps ax -o pid=,args= 2>/dev/null | awk '$2 == "npm" && $3 == "run" && $4 == "dev"')

while IFS= read -r line; do
	[[ "$line" == LISTEN* ]] || continue
	local_addr="$(awk '{print $4}' <<<"$line")"
	port="$(port_from_addr "$local_addr")"
	[[ "$port" == "4321" ]] || continue

	rest="${line#*users:(}"
	while [[ "$rest" =~ pid=([0-9]+) ]]; do
		pid="${BASH_REMATCH[1]}"
		rest="${rest#*pid=${pid}}"
		[[ -z "${captured_pids[$pid]:-}" ]] || continue

		cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || echo "?")
		label=$(short_path "$cwd")
		echo "${label}|${port}|${pid}"
	done
done < <(ss -tlnp 2>/dev/null || true)
