#!/usr/bin/env bash

get_ip() {
    timeout 3 curl -s https://api.ipify.org 2>/dev/null || echo "N/A"
}

if [[ "$1" == "--copy" ]]; then
    ip=$(get_ip)
    echo -n "$ip" | wl-copy
    dunstify "IP address copied!"
    exit 0
fi

ip=$(get_ip)
echo "{\"text\": \"${ip}\"}"
