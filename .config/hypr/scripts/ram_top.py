#!/usr/bin/env python3
"""Print top RAM consumers grouped by app. Lines: name|rss_kib|pid,pid,..."""

from __future__ import annotations

import os
from collections import defaultdict

PAGE_SIZE = os.sysconf("SC_PAGE_SIZE")
TOP_N = 10

# Child helpers that should inherit the parent's app name.
GENERIC = {
    "electron",
    "chrome_crashpad",
    "mainthread",
    "node-mainthread",
    "isolated web co",
    "isolated servic",
    "web content",
    "webextensions",
    "rdd process",
    "socket process",
    "utility process",
    "privileged cont",
    "zygote",
    "broker",
    "gpu process",
    "renderer",
    "forkserver",
}


def read_proc(path: str, binary: bool = False) -> bytes | str | None:
    try:
        if binary:
            with open(path, "rb") as fh:
                return fh.read()
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return None


def classify(comm: str, exe_base: str, cmdline: str) -> str:
    low = f"{cmdline} {exe_base} {comm}".lower()
    if "cursor" in low or "/usr/share/cursor" in low:
        return "cursor"
    if "zen-bin" in low or "/zen/" in low or exe_base.startswith("zen"):
        return "zen"
    if "discord" in low:
        return "discord"
    if "slack" in low:
        return "slack"
    if "spotify" in low:
        return "spotify"
    if "code" in low and "cursor" not in low:
        return "code"
    if exe_base in ("firefox", "firefox-bin"):
        return "firefox"

    base = exe_base[:-4] if exe_base.endswith("-bin") else exe_base
    if base and base != "exe" and not base.startswith("["):
        return base

    return (comm.split() or ["unknown"])[0].lower()


def main() -> None:
    procs: dict[int, dict] = {}
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        pid = int(entry)
        stat = read_proc(f"/proc/{pid}/stat")
        if not isinstance(stat, str):
            continue
        # Fields after "(comm)": state ppid ... rss(field 24 => index 21).
        rparen = stat.rfind(")")
        if rparen < 0:
            continue
        lparen = stat.find("(")
        if lparen < 0 or lparen >= rparen:
            continue
        comm = stat[lparen + 1 : rparen]
        tail = stat[rparen + 2 :].split()
        if len(tail) < 22:
            continue
        try:
            ppid = int(tail[1])
            rss_kib = int(tail[21]) * PAGE_SIZE // 1024
        except ValueError:
            continue
        if rss_kib <= 0:
            continue

        exe_base = ""
        try:
            exe_base = os.path.basename(os.readlink(f"/proc/{pid}/exe"))
        except OSError:
            pass

        name = classify(comm, exe_base, "")
        if name.lower() in GENERIC or comm.lower() in GENERIC:
            raw_cmd = read_proc(f"/proc/{pid}/cmdline", binary=True) or b""
            if isinstance(raw_cmd, bytes) and raw_cmd:
                cmdline = raw_cmd.replace(b"\x00", b" ").decode("utf-8", "replace").strip()
                name = classify(comm, exe_base, cmdline)

        procs[pid] = {
            "ppid": ppid,
            "rss": rss_kib,
            "comm": comm,
            "name": name,
        }

    def resolved_name(pid: int) -> str:
        seen: set[int] = set()
        cur = pid
        fallback = procs[pid]["name"]
        while cur in procs and cur not in seen:
            seen.add(cur)
            info = procs[cur]
            name = info["name"]
            if name.lower() not in GENERIC and info["comm"].lower() not in GENERIC:
                return name
            cur = info["ppid"]
        return fallback

    groups: dict[str, dict] = defaultdict(lambda: {"rss": 0, "pids": []})
    for pid, info in procs.items():
        key = resolved_name(pid)
        groups[key]["rss"] += info["rss"]
        groups[key]["pids"].append(pid)

    top = sorted(groups.items(), key=lambda item: item[1]["rss"], reverse=True)[:TOP_N]
    for name, data in top:
        pids = ",".join(str(p) for p in data["pids"])
        print(f"{name}|{data['rss']}|{pids}")


if __name__ == "__main__":
    main()
