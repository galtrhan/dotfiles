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

OPTIONS_FILE=$(mktemp --suffix=-clipboard-menu)
trap 'rm -f "${OPTIONS_FILE}"' EXIT
printf '%s\n' "${PREVIEWS[@]}" >"${OPTIONS_FILE}"

# Options go through a file: `qs ipc call` corrupts arguments above ~22 KB,
# which a full cliphist list (500 entries) easily reaches.
SELECTED=$("$SCRIPT_DIR/qs-menu.sh" --file "${OPTIONS_FILE}" "Clipboard")
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
