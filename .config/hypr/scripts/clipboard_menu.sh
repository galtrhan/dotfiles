#!/bin/bash
# Clipboard history picker via QuickShell launcher.
# Shows cliphist previews without entry IDs; copies the selected item.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mapfile -t LINES < <(cliphist list)
if [[ ${#LINES[@]} -eq 0 ]]; then
    notify-send "Clipboard" "No clipboard history."
    exit 1
fi

PREVIEWS=()
for line in "${LINES[@]}"; do
    # cliphist list: "ID<tab>preview"
    PREVIEWS+=("${line#*$'\t'}")
done

SELECTED=$("$SCRIPT_DIR/qs-menu.sh" "Clipboard" "${PREVIEWS[@]}")
if [[ -z "${SELECTED}" ]]; then
    exit 1
fi

for line in "${LINES[@]}"; do
    preview="${line#*$'\t'}"
    if [[ "${preview}" == "${SELECTED}" ]]; then
        printf '%s' "${line}" | cliphist decode | wl-copy
        exit 0
    fi
done

exit 1
