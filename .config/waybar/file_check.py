#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
file_check.py

Python version of the Waybar helper created previously as a shell script.

- Default behavior (status): print a single-line JSON object for Waybar describing
  whether a target file exists.
- Click/open behavior: run different actions depending on whether the file exists.
- Supports commands:
    status (default), open|click, create, remove
- You can override the target file with:
    - Environment variable: FILE_CHECK_PATH
    - Or pass the path as the second argument: file_check.py status /path/to/file
- You can customize actions by setting environment variables:
    OPEN_CMD, CREATE_CMD, REMOVE_CMD
  If they contain "%s" they will be formatted with the file path and executed via shell.
  Otherwise they will be executed directly with the file path as the final argument.

Example Waybar config snippet:
{
  "custom/file_check": {
    "format": "{text}",
    "return-type": "json",
    "interval": 5,
    "exec": "/home/<user>/.config/waybar/file_check.py status /path/to/watched_file",
    "on-click": "/home/<user>/.config/waybar/file_check.py open /path/to/watched_file",
    "tooltip": true
  }
}
"""

from __future__ import annotations

import json
import os
import shlex
import shutil
import subprocess
import sys
import time
from typing import List, Optional

# ---------- Defaults (override via env) ----------
DEFAULT_FILE = os.path.expanduser(
    os.environ.get(
        "FILE_CHECK_PATH",
        os.path.join(os.path.expanduser("~"), ".config", "waybar", "important_file"),
    )
)
OPEN_CMD_ENV = os.environ.get("OPEN_CMD", "xdg-open")
CREATE_CMD_ENV = os.environ.get("CREATE_CMD", "")  # if empty, use builtin create
REMOVE_CMD_ENV = os.environ.get("REMOVE_CMD", "")  # if empty, use builtin remove
# -------------------------------------------------


def usage() -> None:
    prog = os.path.basename(sys.argv[0])
    print(
        f"Usage: {prog} [status|open|click|create|remove] [file_path]\n"
        "  status|<no-arg>   Print JSON status for Waybar (default)\n"
        "  open|click        Perform action depending on file state (open or create+open)\n"
        "  create            Create the file (and parent dir)\n"
        "  remove            Remove the file\n"
        "You can override the target file by setting FILE_CHECK_PATH env var or passing a path as second arg.",
        file=sys.stderr,
    )


def file_exists(path: str) -> bool:
    return os.path.isfile(path)


def json_status(path: str) -> str:
    name = os.path.basename(path)
    if file_exists(path):
        icon = ""  # check icon
        tooltip = f"File exists: {path}"
        cls = "present"
        text = f"{icon} {name}"
    else:
        icon = ""  # plus/add icon for absent
        tooltip = f"File missing: {path}"
        cls = "absent"
        text = ""

    payload = {"text": text, "tooltip": tooltip, "class": cls}
    return json.dumps(payload, ensure_ascii=False)


def _run_shell(cmdline: str, background: bool = False) -> int:
    """
    Run a shell command via /bin/sh -c. If background is True, spawn and return immediately.
    Returns the exit code for foreground execution, or 0 for background spawn (cannot determine).
    """
    if background:
        # Use Popen to avoid blocking; detach from parent so Waybar click returns.
        subprocess.Popen(
            cmdline,
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            close_fds=True,
            start_new_session=True,
        )
        return 0
    else:
        return subprocess.call(cmdline, shell=True)


def _run_program(argv: List[str], background: bool = False) -> int:
    """
    Run a program by argv list. If background True, spawn and return immediately.
    """
    if background:
        subprocess.Popen(
            argv,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            close_fds=True,
            start_new_session=True,
        )
        return 0
    else:
        try:
            return subprocess.call(argv)
        except FileNotFoundError:
            return 127


def _execute_command_template(
    template: str, target: str, background: bool = False
) -> int:
    """
    Execute a user-provided command template:
      - If template contains %s -> format and run via shell
      - Else -> treat as program and pass target as final argument
    """
    if "%s" in template:
        cmdline = template % target
        return _run_shell(cmdline, background=background)
    else:
        # Split template to argv safely
        argv = shlex.split(template)
        argv.append(target)
        return _run_program(argv, background=background)


def open_action(path: str) -> None:
    """
    If file exists -> run OPEN_CMD (background)
    If missing    -> create it (builtin or CREATE_CMD) then open
    """
    if file_exists(path):
        _execute_or_builtin_open(path)
    else:
        # create then open
        do_create(path)
        # small delay to ensure file system settled if necessary
        time.sleep(0.05)
        _execute_or_builtin_open(path)


def _execute_or_builtin_open(path: str) -> None:
    if OPEN_CMD_ENV:
        try:
            _execute_command_template(OPEN_CMD_ENV, path, background=True)
        except Exception:
            # fallback to builtin open via xdg-open if available
            if shutil.which("xdg-open"):
                _run_program(["xdg-open", path], background=True)
    else:
        if shutil.which("xdg-open"):
            _run_program(["xdg-open", path], background=True)


def do_create(path: str) -> None:
    if CREATE_CMD_ENV:
        try:
            _execute_command_template(CREATE_CMD_ENV, path, background=False)
            return
        except Exception:
            pass
    # builtin create: mkdir -p dirname && touch file
    parent = os.path.dirname(path) or "."
    os.makedirs(parent, exist_ok=True)
    # create the file if it doesn't exist
    open(path, "a").close()


def do_remove(path: str) -> None:
    if REMOVE_CMD_ENV:
        try:
            _execute_command_template(REMOVE_CMD_ENV, path, background=False)
            return
        except Exception:
            pass
    # builtin remove
    try:
        if os.path.exists(path):
            if os.path.isdir(path):
                # If user tries to remove a directory, do nothing to avoid surprises.
                # You can override via REMOVE_CMD_ENV if you need other behavior.
                return
            os.remove(path)
    except Exception:
        pass


def main(argv: Optional[List[str]] = None) -> int:
    if argv is None:
        argv = sys.argv[1:]

    cmd = "status"
    target = DEFAULT_FILE

    if len(argv) >= 1:
        first = argv[0].lower()
        if first in ("status", "open", "click", "create", "remove"):
            cmd = first
            if len(argv) >= 2 and argv[1]:
                target = argv[1]
        else:
            # If the first arg is not a known command but is present and looks like a path,
            # treat it as a direct status query (backwards compat).
            if len(argv) == 1:
                # treat as "status target"
                cmd = "status"
                target = argv[0]
            elif len(argv) >= 2:
                # treat first as command and second as path
                cmd = first
                target = argv[1]

    # If environment variable is present, override unless a CLI path was provided explicitly.
    env_path = os.environ.get("FILE_CHECK_PATH")
    if env_path and (len(argv) < 2):
        target = env_path

    if cmd in ("-h", "--help"):
        usage()
        return 0

    if cmd == "status":
        print(json_status(target), flush=True)
        return 0

    if cmd in ("open", "click"):
        # perform the open behavior, but don't block: open_action spawns background opener
        try:
            open_action(target)
        finally:
            # print updated status for Waybar
            time.sleep(0.02)
            print(json_status(target), flush=True)
        return 0

    if cmd == "create":
        do_create(target)
        time.sleep(0.02)
        print(json_status(target), flush=True)
        return 0

    if cmd == "remove":
        do_remove(target)
        time.sleep(0.02)
        print(json_status(target), flush=True)
        return 0

    # Unknown - print usage
    usage()
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(1)
