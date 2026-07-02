#!/bin/bash
# Quickshell menu picker for script use.
# Usage: qs-menu.sh [--compact] "Prompt" ["Option 1" "Option 2" ...]
#        echo "Option 1\nOption 2" | qs-menu.sh [--compact] "Prompt"
# Prints the selected option to stdout, or nothing if cancelled.
#
# Default: wide picker with search (recording, clipboard, etc.)
# --compact: narrow centered menu (power menu)
# Options may be passed as arguments or on stdin (one per line).

set -euo pipefail

COMPACT=false
if [[ "${1:-}" == "--compact" ]]; then
    COMPACT=true
    shift
fi

if [[ $# -lt 1 ]]; then
    echo "Usage: qs-menu.sh [--compact] \"Prompt\" \"Option 1\" [\"Option 2\" ...]" >&2
    exit 1
fi

TITLE="$1"
shift

if [[ $# -eq 0 ]]; then
    if [[ -t 0 ]]; then
        echo "No menu options provided." >&2
        exit 1
    fi
    OPTIONS=$(cat)
    if [[ -z "$OPTIONS" ]]; then
        echo "No menu options provided." >&2
        exit 1
    fi
else
    OPTIONS=$(printf '%s\n' "$@")
fi

if [[ "$COMPACT" == true ]]; then
    qs ipc call -- menu show "$TITLE" "$OPTIONS" >/dev/null
else
    qs ipc call -- menu show_search "$TITLE" "$OPTIONS" >/dev/null
fi

if ! SELECTED=$(qs ipc wait menu selected 2>/dev/null); then
    exit 1
fi

printf '%s' "$SELECTED"
