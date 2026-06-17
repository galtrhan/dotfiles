#!/bin/sh
names=$(lnd)
date=$(date "+%H:%M   %Y.%m.%d")
alt=$(date "+%Y.%m.%d")
printf '{"text":"%s","alt":"%s","tooltip":"%s","class":"namedays"}\n' "$date" "$alt" "$names"
