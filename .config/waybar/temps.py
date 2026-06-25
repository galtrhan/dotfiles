#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys


def get_sensors():
    try:
        result = subprocess.run(
            ["sensors", "-j"], capture_output=True, text=True, timeout=5
        )
        return json.loads(result.stdout)
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        return {}


def parse_temps(data):
    temps = []
    for chip, entries in data.items():
        if not isinstance(entries, dict):
            continue
        for label, readings in entries.items():
            if label == "Adapter" or not isinstance(readings, dict):
                continue
            for key, val in readings.items():
                m = re.match(r"temp(\d+)_input", key)
                if m and isinstance(val, (int, float)) and 0 < val < 200:
                    idx = m.group(1)
                    crit = readings.get(f"temp{idx}_crit")
                    temps.append((chip, label, val, crit))
    return temps


def find_cpu_temp(temps):
    for target in ["Package id 0", "CPU", "Tctl", "Tdie"]:
        for chip, label, val, _ in temps:
            if label == target:
                return val
    relevant = [
        val
        for chip, label, val, _ in temps
        if any(kw in chip for kw in ["coretemp", "k10temp", "thinkpad"])
    ]
    if relevant:
        return max(relevant)
    return max(t[2] for t in temps) if temps else 0


def get_class(temp):
    if temp < 40:
        return "cool"
    elif temp >= 75:
        return "critical"
    elif temp >= 60:
        return "warning"
    return ""


def build_tooltip(temps):
    lines = []
    for chip, label, val, crit in sorted(temps, key=lambda t: -t[2]):
        crit_str = f" (crit {crit:.0f}°C)" if crit else ""
        lines.append(f"{label}: {val:.0f}°C{crit_str}")
    return "\n".join(lines)


def notify(temps):
    lines = []
    for chip, label, val, crit in sorted(temps, key=lambda t: -t[2]):
        crit_str = f" (crit {crit:.0f}°C)" if crit else ""
        lines.append(f"{label}: {val:.0f}°C{crit_str}")
    body = "\n".join(lines)
    subprocess.run(
        ["dunstify", "-a", "waybar", "-u", "normal", "Temperatures", body],
        capture_output=True,
    )


HISTORY_FILE = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "waybar-temps.json"
)
HISTORY_SIZE = 12


def rolling_average(current: float) -> int:
    history = []
    if os.path.exists(HISTORY_FILE):
        try:
            with open(HISTORY_FILE) as f:
                history = json.load(f)
        except (json.JSONDecodeError, OSError):
            history = []
    history.append(current)
    history = history[-HISTORY_SIZE:]
    try:
        with open(HISTORY_FILE, "w") as f:
            json.dump(history, f)
    except OSError:
        pass
    return int(round(sum(history) / len(history)))


def main():
    data = get_sensors()
    temps = parse_temps(data)

    if len(sys.argv) > 1 and sys.argv[1] == "--notify":
        notify(temps)
        return

    if not temps:
        print(json.dumps({"text": " ??°C", "tooltip": "No temperature data"}))
        return

    cpu_temp = find_cpu_temp(temps)
    display = rolling_average(cpu_temp)

    out = {
        "text": f" {display}°C",
        "tooltip": build_tooltip(temps),
    }

    klass = get_class(display)
    if klass:
        out["class"] = klass

    print(json.dumps(out))


if __name__ == "__main__":
    main()
