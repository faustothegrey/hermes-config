#!/usr/bin/env python3
"""Hermes peer heartbeat — silent health logger for cron no_agent=True jobs.
Polls a peer's /health endpoint and appends one JSONL line to a log file.
No LLM cost, no delivery, no alerts — data collection only.
"""
import json
import os
import sys
from datetime import datetime, timezone
from urllib.request import Request, urlopen
from urllib.error import URLError

PEER_URL = os.getenv("PEER_HEALTH_URL", "http://192.168.178.105:8642/health")
PEER_NAME = os.getenv("PEER_NAME", "peer105")
LOG_DIR = os.path.expanduser("~/.hermes/peer-monitor")
LOG_FILE = os.path.join(LOG_DIR, f"{PEER_NAME}-health.jsonl")

os.makedirs(LOG_DIR, exist_ok=True)

entry = {
    "ts": datetime.now(timezone.utc).isoformat(),
    "peer": PEER_NAME,
    "url": PEER_URL,
}

try:
    req = Request(PEER_URL, headers={"User-Agent": f"hermes-{PEER_NAME}-heartbeat/1.0"})
    with urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read())
        entry["status"] = data.get("status", "unknown")
        entry["platform"] = data.get("platform", "unknown")
        entry["http_status"] = resp.status
except URLError as e:
    entry["status"] = "down"
    entry["error"] = str(e.reason)
except Exception as e:
    entry["status"] = "error"
    entry["error"] = str(e)

with open(LOG_FILE, "a") as f:
    f.write(json.dumps(entry) + "\n")
