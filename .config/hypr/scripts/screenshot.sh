#!/usr/bin/env bash

usage() {
    echo "Usage: $0 <filename>"
}

# main
if [[ $# -eq 0 ]]; then
    usage
    exit 2
fi

cmd="status"
waybar=false
audio=false

while [ $# -gt 0 ]; do
    arg=$1
    shift

    case $arg in
        "start")
            cmd="start"
            ;;
        "stop")
            cmd="stop"
            ;;
        -a|--audio)
            audio=true
            ;;
        -w|--waybar)
            waybar=true
            ;;
    esac
done

case $cmd in
    "start")
        ;;
    "stop")
        ;;
esac

exit 1
