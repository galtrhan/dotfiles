#!/bin/bash
# Quickshell menu picker for script use.
# Usage: qs-menu.sh [--compact] "Prompt" ["Option 1" "Option 2" ...]
#        echo "Option 1\nOption 2" | qs-menu.sh [--compact] "Prompt"
#        qs-menu.sh --file /path/to/options "Prompt"
# Prints the selected option to stdout, or nothing if cancelled.
#
# Default: wide picker with search (recording, clipboard, etc.)
# --compact: narrow centered menu (power menu)
# --file: read options from a file and hand the menu the path. Use this for
#         long lists: `qs ipc call` corrupts arguments above roughly 22 KB.
# Options may be passed as arguments or on stdin (one per line).

set -euo pipefail

COMPACT=false
FILE=""
while [[ $# -gt 0 ]]; do
    case "${1:-}" in
        --compact) COMPACT=true; shift ;;
        --file)
            FILE="${2:-}"
            shift
            shift || true
            ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "Usage: qs-menu.sh [--compact] [--file PATH] \"Prompt\" \"Option 1\" [\"Option 2\" ...]" >&2
    exit 1
fi

TITLE="$1"
shift

if [[ -n "${FILE}" ]]; then
    if [[ ! -r "${FILE}" ]]; then
        echo "Cannot read options file: ${FILE}" >&2
        exit 1
    fi
elif [[ $# -eq 0 ]]; then
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

if [[ -n "${FILE}" ]]; then
    qs ipc call -- menu show_search_file "$TITLE" "$FILE" >/dev/null || exit 1
elif [[ "$COMPACT" == true ]]; then
    qs ipc call -- menu show "$TITLE" "$OPTIONS" >/dev/null
else
    qs ipc call -- menu show_search "$TITLE" "$OPTIONS" >/dev/null
fi

if ! SELECTED=$(timeout 120 qs ipc wait menu selected 2>/dev/null); then
    exit 1
fi

printf '%s' "$SELECTED"
