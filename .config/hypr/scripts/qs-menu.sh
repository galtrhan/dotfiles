#!/bin/bash
# Quickshell menu picker for script use.
# Usage: qs-menu.sh [--compact] "Prompt" "Option 1" "Option 2" ...
# Prints the selected option to stdout, or nothing if cancelled.
#
# Default: wide picker with search (recording, clipboard, etc.)
# --compact: narrow centered menu (power menu)

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
    echo "No menu options provided." >&2
    exit 1
fi

OPTIONS=$(printf '%s\n' "$@")

if [[ "$COMPACT" == true ]]; then
    qs ipc call -- menu show "$TITLE" "$OPTIONS" >/dev/null
else
    qs ipc call -- menu show_search "$TITLE" "$OPTIONS" >/dev/null
fi

if ! SELECTED=$(qs ipc wait menu selected 2>/dev/null); then
    exit 1
fi

printf '%s' "$SELECTED"
