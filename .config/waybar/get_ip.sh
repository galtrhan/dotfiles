#!/usr/bin/env bash

# Get external IP address for waybar display

ip=$(timeout 3 curl -s https://api.ipify.org 2>/dev/null || echo "N/A")
echo "{\"text\": \"${ip}\"}"
