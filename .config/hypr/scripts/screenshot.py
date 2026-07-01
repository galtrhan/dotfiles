#!/usr/bin/env python3

import argparse
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser(
        description="A script to manage a screen capture, with optional audio."
    )

    parser.add_argument(
        "command",
        choices=["start", "stop"],
        help="Command to execute: start or stop the service",
    )
    parser.add_argument(
        "-a", "--audio", action="store_true", help="Enable audio capture"
    )

    args = parser.parse_args()
    cmd = args.command

    audio_enabled = args.audio

    # filename = current timestamp + ".mp4"
    filename = f"{int(time.time())}.mp4"

    if cmd == "start":
        geometry = subprocess.run(
            ["slurp", "-d", '-F "JetBrainsMono Nerd Font"'],
            capture_output=True,
            text=True,
        )
        subprocess.run(
            [
                "wf-recorder",
                f"-g {geometry.stdout.strip()}",
                "-a" if audio_enabled else "",
                f"-f{filename}",
            ]
        )
        sys.exit(0)

    elif cmd == "stop":
        subprocess.run(["ls", "-lha"])
        sys.exit(0)


if __name__ == "__main__":
    main()
