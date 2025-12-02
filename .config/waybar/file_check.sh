#!/usr/bin/env bash
#
# file_check.sh
#
# Waybar custom module helper:
# - When executed with no arguments (or "status") it prints a single-line JSON object
#   describing whether the target file exists. Use this with Waybar's "exec" module.
# - When called with "open" or "click" it performs an action depending on the file state:
#     * if the file exists -> open it with $OPEN_CMD (defaults to xdg-open)
#     * if it doesn't     -> create it (via $CREATE_CMD) and then open it
# - Supports "create" and "remove" explicit actions.
#
# Configuration:
# - Set the file to check with the env var FILE_CHECK_PATH or pass as the second argument.
#   Example: FILE_CHECK_PATH="$HOME/.config/some/flag" $HOME/.config/waybar/file_check.sh
#
# Example Waybar config snippet (jsonc):
# "custom/file_check": {
#   "format": "{text}",
#   "return-type": "json",
#   "exec": "$HOME/.config/waybar/file_check.sh",
#   "on-click": "$HOME/.config/waybar/file_check.sh open"
# }
#
# Notes:
# - The script tries to be POSIX-friendly but uses Bash string replacements for JSON escaping.
# - Adjust OPEN_CMD / CREATE_CMD / REMOVE_CMD environment variables if you want custom behavior.

set -u
set -o pipefail 2>/dev/null || true

# ---------- Configuration (override via env) ----------
FILE_CHECK_PATH="${FILE_CHECK_PATH:-$HOME/.config/waybar/important_file}"
OPEN_CMD="${OPEN_CMD:-xdg-open}"        # Command used to open the file (should not block)
CREATE_CMD="${CREATE_CMD:-sh -c 'mkdir -p \"$(dirname \"$1\")\" && touch \"$1\"' --}" # $1 will be file path
REMOVE_CMD="${REMOVE_CMD:-rm -f}"       # Command to remove the file
# -----------------------------------------------------

# Helper: print usage
usage() {
  cat <<EOF
Usage: $(basename "$0") [status|open|click|create|remove] [file_path]
  status|<no-arg>   Print JSON status for Waybar (default)
  open|click        Perform action depending on file state (open or create+open)
  create            Create the file (and parent dir)
  remove            Remove the file
You can override the target file by setting FILE_CHECK_PATH env var or passing a path as second arg.
EOF
}

# Helper: JSON escape for strings (basic)
json_escape() {
  local s="$1"
  # escape backslashes and double quotes
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  # escape newlines
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# Resolve args
cmd="${1:-status}"
# allow optional file path as second argument
if [ "${2:-}" != "" ]; then
  FILE_CHECK_PATH="$2"
fi

# Determine status
file_exists() {
  [ -f "$FILE_CHECK_PATH" ]
}

# Action handlers
do_open() {
  if file_exists; then
    # Try to open without blocking Waybar: spawn in background.
    # If OPEN_CMD contains placeholders or expects the file as $1, handle generically:
    if printf '%s' "$OPEN_CMD" | grep -q '%s'; then
      # replace %s with file path
      cmdline="$(printf "$OPEN_CMD" "$FILE_CHECK_PATH")"
      sh -c "$cmdline" >/dev/null 2>&1 &
    else
      # run command with file path as argument (most common)
      $OPEN_CMD "$FILE_CHECK_PATH" >/dev/null 2>&1 &
    fi
    return 0
  else
    # create then open
    # CREATE_CMD may be a wrapper that expects the file as $1; we execute using "sh -c" if it's a compound
    if printf '%s' "$CREATE_CMD" | grep -q '%s'; then
      cmdline="$(printf "$CREATE_CMD" "$FILE_CHECK_PATH")"
      sh -c "$cmdline"
    else
      # If CREATE_CMD is the default we set, it uses the positional parameter technique:
      # it was defined as: sh -c 'mkdir -p "$(dirname "$1")" && touch "$1"' --
      # so execute preserving that behavior:
      if [ "${CREATE_CMD%% *}" = "sh" ]; then
        # execute the create command (it's expected to accept the file as $1)
        eval "$CREATE_CMD" "'$FILE_CHECK_PATH'"
      else
        # fallback: try simple mkdir+touch
        mkdir -p "$(dirname "$FILE_CHECK_PATH")"
        touch "$FILE_CHECK_PATH"
      fi
    fi

    # then open
    do_open
    return 0
  fi
}

do_create() {
  if printf '%s' "$CREATE_CMD" | grep -q '%s'; then
    cmdline="$(printf "$CREATE_CMD" "$FILE_CHECK_PATH")"
    sh -c "$cmdline"
  else
    if [ "${CREATE_CMD%% *}" = "sh" ]; then
      eval "$CREATE_CMD" "'$FILE_CHECK_PATH'"
    else
      mkdir -p "$(dirname "$FILE_CHECK_PATH")"
      touch "$FILE_CHECK_PATH"
    fi
  fi
}

do_remove() {
  $REMOVE_CMD "$FILE_CHECK_PATH"
}

# Produce JSON status for Waybar
print_status() {
  local name icon tooltip class
  name="$(basename "$FILE_CHECK_PATH")"

  if file_exists; then
    icon=""          # checkmark document-like icon
    tooltip="File exists: $FILE_CHECK_PATH"
    class="present"
  else
    icon=""          # plus/add icon to indicate absent (choose any you prefer)
    tooltip="File missing: $FILE_CHECK_PATH"
    class="absent"
  fi

  # Compose JSON. Waybar accepts {"text":"...","tooltip":"...","class":"..."}.
  # Escape values properly.
  esc_text="$(json_escape "$icon $name")"
  esc_tooltip="$(json_escape "$tooltip")"
  esc_class="$(json_escape "$class")"

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$esc_text" "$esc_tooltip" "$esc_class"
}

# Main dispatch
case "$cmd" in
  status)
    print_status
    ;;
  open|click)
    do_open
    # After performing the action, also print updated status (Waybar expects output)
    # small delay to allow create+open to finish if it created file
    sleep 0.05
    print_status
    ;;
  create)
    do_create
    sleep 0.05
    print_status
    ;;
  remove)
    do_remove
    sleep 0.05
    print_status
    ;;
  -h|--help)
    usage
    ;;
  *)
    # allow direct invocation with a file path as first arg (backwards compat)
    if [ -n "$1" ] && [ -f "$1" ]; then
      FILE_CHECK_PATH="$1"
      print_status
    else
      usage
      exit 2
    fi
    ;;
esac

exit 0
