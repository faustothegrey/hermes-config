#!/usr/bin/env python3
"""Print Codex / ChatGPT-plan usage from the local Codex CLI auth.

Uses the official Codex app-server JSON-RPC method `account/rateLimits/read`.
Requires `codex login` with ChatGPT auth. Does not read or print tokens.
"""
from __future__ import annotations

import datetime as _dt
import json
import select
import shutil
import subprocess
import sys
import time


def _send(proc: subprocess.Popen[str], obj: dict) -> None:
    assert proc.stdin is not None
    proc.stdin.write(json.dumps(obj, separators=(",", ":")) + "\n")
    proc.stdin.flush()


def _recv_id(proc: subprocess.Popen[str], target: int, timeout: float = 30.0) -> dict:
    assert proc.stdout is not None
    deadline = time.time() + timeout
    while time.time() < deadline:
        readable, _, _ = select.select([proc.stdout], [], [], max(0, deadline - time.time()))
        if not readable:
            break
        line = proc.stdout.readline()
        if not line:
            break
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue
        if msg.get("id") == target:
            return msg
    raise TimeoutError(f"No Codex app-server response for id={target}")


def _fmt_reset(ts: int | float | None) -> str:
    if not ts:
        return "unknown"
    now = time.time()
    dt = _dt.datetime.fromtimestamp(float(ts)).astimezone()
    remaining = max(0, float(ts) - now)
    days = int(remaining // 86400)
    remaining -= days * 86400
    hours = int(remaining // 3600)
    remaining -= hours * 3600
    mins = int(remaining // 60)
    if days:
        left = f"{days}d {hours}h {mins}m"
    else:
        left = f"{hours}h {mins}m"
    return f"{dt:%Y-%m-%d %H:%M:%S %Z} ({left})"


def main() -> int:
    codex = shutil.which("codex")
    if not codex:
        print("codex CLI not found", file=sys.stderr)
        return 1

    proc = subprocess.Popen(
        [codex, "app-server", "--listen", "stdio://"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    try:
        _send(
            proc,
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "clientInfo": {
                        "name": "hermes-codex-usage-status",
                        "version": "1.0",
                        "title": "Hermes",
                    },
                    "capabilities": {},
                    "protocolVersion": "0.1.0",
                },
            },
        )
        _recv_id(proc, 1, timeout=20)
        _send(proc, {"jsonrpc": "2.0", "id": 2, "method": "account/rateLimits/read", "params": {}})
        msg = _recv_id(proc, 2, timeout=30)
        if "error" in msg:
            print(json.dumps(msg["error"], indent=2), file=sys.stderr)
            return 2
        rl = (msg.get("result") or {}).get("rateLimits") or {}
        primary = rl.get("primary") or {}
        secondary = rl.get("secondary") or {}
        credits = rl.get("credits") or {}
        print(f"Login/status: data returned by Codex app-server")
        print(f"Plan: {rl.get('planType', 'unknown')}")
        print(f"Limit bucket: {rl.get('limitId', 'unknown')}")
        print(f"5-hour usage: {primary.get('usedPercent', 'unknown')}% used")
        print(f"5-hour reset: {_fmt_reset(primary.get('resetsAt'))}")
        print(f"7-day usage: {secondary.get('usedPercent', 'unknown')}% used")
        print(f"7-day reset: {_fmt_reset(secondary.get('resetsAt'))}")
        print(
            "Credits: "
            f"hasCredits={credits.get('hasCredits')}, "
            f"unlimited={credits.get('unlimited')}, "
            f"balance={credits.get('balance')}"
        )
        print(f"Rate limited now: {rl.get('rateLimitReachedType') or 'no'}")
        return 0
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    raise SystemExit(main())
