#!/bin/bash

notify-send -u critical -t 5000 "sudo" "Password required"

qs ipc call -- menu show_password "sudo password" >/dev/null
PASSWORD=$(qs ipc wait menu passwordEntered 2>/dev/null || true)

echo "$PASSWORD"
