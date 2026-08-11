#!/usr/bin/env python3
"""QuickShell Cursor usage widget: fetch plan pools from cursor.com/api/usage-summary."""

from __future__ import annotations

import base64
import json
import os
import re
import sqlite3
import subprocess
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

USAGE_URL = "https://cursor.com/api/usage-summary"
HTTP_TIMEOUT_SEC = 10
FALLBACK_UA_VERSION = "2026.05.24-dda726e"
_CURSOR_UA: str | None = None


def state_db_path() -> Path:
    config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config / "Cursor" / "User" / "globalStorage" / "state.vscdb"


def cursor_agent_ua() -> str:
    global _CURSOR_UA
    if _CURSOR_UA is not None:
        return _CURSOR_UA

    try:
        out = subprocess.run(
            ["cursor-agent", "--version"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        version = out.stdout.strip().split()[-1] if out.stdout.strip() else ""
        if version:
            _CURSOR_UA = f"cursor-agent/{version}"
            return _CURSOR_UA
    except (OSError, subprocess.SubprocessError):
        pass

    _CURSOR_UA = f"cursor-agent/{FALLBACK_UA_VERSION}"
    return _CURSOR_UA


def fail(status: str, error: str) -> None:
    print(json.dumps({"status": status, "error": error, "account": None, "plan": None, "meters": []}))


def jwt_claims(token: str) -> dict[str, Any]:
    payload = token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))


def read_state_keys(path: Path, keys: list[str]) -> dict[str, str | None]:
    placeholders = ",".join("?" * len(keys))
    con = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        rows = con.execute(
            f"SELECT key, value FROM ItemTable WHERE key IN ({placeholders})",
            keys,
        ).fetchall()
        out: dict[str, str | None] = {key: None for key in keys}
        for key, value in rows:
            if isinstance(value, bytes):
                value = value.decode("utf-8", "replace")
            out[key] = value
        return out
    finally:
        con.close()


def extract_percent(message: str | None) -> float | None:
    if not message:
        return None
    match = re.search(r"(\d+(?:\.\d+)?)\s*%", message)
    if not match:
        return None
    return float(match.group(1))


def meter(pool_id: str, title: str, used_percent: float) -> dict[str, Any]:
    used = max(0.0, min(100.0, used_percent))
    return {"id": pool_id, "title": title, "percent": used / 100.0}


def meters_from_summary(summary: dict[str, Any]) -> list[dict[str, Any]]:
    individual = summary.get("individualUsage") or {}
    plan = individual.get("plan") or {}
    meters: list[dict[str, Any]] = []

    auto = plan.get("autoPercentUsed")
    if auto is not None:
        meters.append(meter("included", "Auto + Composer", float(auto)))

    api = plan.get("apiPercentUsed")
    if api is not None:
        meters.append(meter("api", "API pool", float(api)))

    if not meters:
        auto_msg = summary.get("autoModelSelectedDisplayMessage")
        named_msg = summary.get("namedModelSelectedDisplayMessage")
        auto_pct = extract_percent(auto_msg if isinstance(auto_msg, str) else None)
        named_pct = extract_percent(named_msg if isinstance(named_msg, str) else None)
        if auto_pct is not None:
            meters.append(meter("included", "Auto + Composer", auto_pct))
        if named_pct is not None:
            meters.append(meter("api", "API pool", named_pct))

    return meters


def main() -> None:
    path = state_db_path()
    if not path.exists():
        fail("auth", f"Cursor state database not found at {path}. Sign in to the Cursor app.")
        return

    try:
        values = read_state_keys(
            path,
            [
                "cursorAuth/accessToken",
                "cursorAuth/cachedEmail",
                "cursorAuth/stripeMembershipType",
            ],
        )
    except sqlite3.Error as exc:
        fail("auth", f"Failed to read Cursor state database at {path}: {exc}")
        return

    raw_token = values.get("cursorAuth/accessToken")
    if not raw_token:
        fail("auth", "Cursor auth not found. Sign in to the Cursor app.")
        return

    token = raw_token.strip().strip('"')
    if token.lower().startswith("bearer "):
        token = token[7:].strip()

    try:
        claims = jwt_claims(token)
    except (IndexError, json.JSONDecodeError, ValueError):
        fail("auth", "Cursor access token is malformed.")
        return

    sub = claims.get("sub")
    if not isinstance(sub, str) or not sub.strip():
        fail("auth", "Cursor access token is missing sub.")
        return

    uid = sub.rsplit("|", 1)[-1].strip()
    if not uid:
        fail("auth", "Cursor access token is missing a user id subject.")
        return

    cookie = f"WorkosCursorSessionToken={uid}%3A%3A{token}"
    email = (values.get("cursorAuth/cachedEmail") or "").strip() or None
    membership = (values.get("cursorAuth/stripeMembershipType") or "").strip() or None

    req = urllib.request.Request(
        USAGE_URL,
        headers={
            "Accept": "application/json",
            "Cookie": cookie,
            "User-Agent": cursor_agent_ua(),
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_SEC) as resp:
            summary = json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        if exc.code in (401, 403):
            fail("auth", "Cursor session was rejected. Open Cursor and sign in again.")
        else:
            fail("error", f"HTTP {exc.code}")
        return
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        fail("error", str(exc))
        return

    meters = meters_from_summary(summary)
    plan = summary.get("membershipType")
    if not isinstance(plan, str):
        plan = membership

    print(
        json.dumps(
            {
                "status": "ok",
                "error": None,
                "account": email,
                "plan": plan,
                "meters": meters,
            }
        )
    )


if __name__ == "__main__":
    main()
