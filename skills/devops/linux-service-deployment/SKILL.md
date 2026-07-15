---
name: linux-service-deployment
description: "Deploy Python API servers and background services as systemd units on Linux. Covers macOS-to-Linux migration, path portability, env-var configuration, log setup, and verification."
tags:
  - linux
  - systemd
  - python
  - api
  - deployment
  - devops
---

# Linux Service Deployment

Deploy a Python API server (or any long-running service) as a systemd service on Linux. Handles the common scenario of porting from macOS launchd to Linux systemd.

**Trigger:** user asks to set up a service to run at startup, or to "make this script a service", or to port a macOS launchd service to Linux.

---

## Core Pattern: macOS → Linux Migration Checklist

When migrating a service from macOS (launchd) to Linux (systemd):

| Concern | macOS (launchd) | Linux (systemd) |
|---------|-----------------|-----------------|
| Service file | `~/Library/LaunchAgents/com.user.name.plist` | `/etc/systemd/system/name.service` |
| Auto-start | `launchctl load/wake` | `systemctl enable` |
| Keep alive | `<key>KeepAlive</key><true/>` | `Restart=on-failure` |
| Logging | `StandardOutPath` / `StandardErrorPath` | `StandardOutput=` / `StandardError=` |
| Env vars | `<key>EnvironmentVariables</key>` | `Environment=` in `[Service]` |

---

## Step 1 — Path Portability

macOS code often has hardcoded paths like `/Users/fausto/Software/...`. Fix these before deploying on Linux:

```python
# BEFORE (macOS hardcoded):
sys.path.insert(0, "/Users/fausto/Software/scripts-ai/quota-monitoring")

# AFTER (portable):
from pathlib import Path
_HOME = Path.home()
_SCRIPTS_AI = _HOME / "Software" / "scripts-ai"
sys.path.insert(0, str(_SCRIPTS_AI / "quota-monitoring"))
```

Similarly fix:
- Plist paths → systemd `WorkingDirectory=`
- Shell paths (`/bin/zsh` → check for `/bin/bash`)
- Any absolute path under `/Users/`

**Pitfall:** check for duplicate imports when reorganising — the old `from pathlib import Path` may still be in the file body after you add one at the top.

---

## Step 2 — Environment-Variable Configuration

Instead of hardcoding host/port/database URLs, make the service configurable via environment variables with sensible defaults:

```python
import os
HOST = os.environ.get("MY_SERVICE_HOST", "127.0.0.1")
PORT = int(os.environ.get("MY_SERVICE_PORT", "9899"))
```

Always default to `127.0.0.1` (localhost-only) for safety. Set `0.0.0.0` explicitly via env var when the service needs to be reachable from other machines on the LAN.

---

## Step 3 — Create the systemd Unit File

Write to `/etc/systemd/system/<name>.service` (requires sudo):

```ini
[Unit]
Description=My Service Description
Documentation=<url>
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=fausto
WorkingDirectory=/home/fausto/Software/scripts-ai/my-service
ExecStart=/usr/bin/python3 /home/fausto/Software/scripts-ai/my-service/server.py
Restart=on-failure
RestartSec=10
Environment=MY_SERVICE_HOST=0.0.0.0
Environment=MY_SERVICE_PORT=9899
StandardOutput=append:/home/fausto/.hermes/logs/my-service.log
StandardError=append:/home/fausto/.hermes/logs/my-service.log

[Install]
WantedBy=multi-user.target
```

Key fields:
- **`Type=simple`** — default, for Python scripts that don't fork
- **`User=`** — run as non-root unless the service needs privileges
- **`WorkingDirectory=`** — the script's working directory (so relative paths work)
- **`Restart=on-failure`** — auto-restart on crash
- **`RestartSec=10`** — pause before restart to avoid restart loops
- **`Environment=`** — one per variable (no `EnvironmentFile` unless you need secrets)
- **`StandardOutput/Error`** — `append:` to a log file

---

## Step 4 — Deploy

```bash
# Copy the unit file (must be root-owned)
sudo cp /tmp/my-service.service /etc/systemd/system/my-service.service

# Reload systemd, enable (start on boot), and start now
sudo systemctl daemon-reload
sudo systemctl enable my-service.service
sudo systemctl start my-service.service
```

---

## Step 5 — Verify

```bash
# Check status
sudo systemctl status my-service.service --no-pager

# Check it's listening (if an HTTP server)
curl -s --max-time 3 http://127.0.0.1:9899/usage | head -20

# Check logs
tail -30 /home/fausto/.hermes/logs/my-service.log
```

Verification checklist:
- ✅ `systemctl is-active` → `active`
- ✅ `systemctl is-enabled` → `enabled`
- ✅ Service responds to requests (curl / health check)
- ✅ Logs show startup message
- ✅ After reboot: `systemctl status` still shows running (test with a restart or schedule a check)

---

## Step 6 — Restarting After Code Changes

```bash
sudo systemctl restart my-service.service
```

No need to `daemon-reload` unless the unit file itself changed. Just restart.

---

## References

- **Pitfall: `--version` vs `-V`** — some older tools (tmux 3.2a) only support `-V`, not `--version`. Test with both.
- **Pitfall: single-threaded HTTPServer** — Python's `http.server.HTTPServer` serves requests sequentially. If a background thread is doing heavy I/O (tmux scraping, subprocess calls), the main thread still answers HTTP. But the server can appear unresponsive during the first heavy fetch because the main thread is... actually, HTTPServer is independent of background threads. If it hangs, check for subprocess deadlocks in the request handler itself.
- **Pitfall: `zsh` not available on Linux** — macOS users often have `zsh` hardcoded in scripts. On Linux, use `bash` or make the shell configurable:
  ```python
  shell = os.environ.get("QUOTA_SHELL", "/bin/bash")
  ```
- **Pitfall: `systemctl edit` vs direct file write** — prefer writing the full unit file with `sudo tee` or `sudo cp`, not `systemctl edit` (which creates drop-in overrides and can be confusing).

## Scripts

See `scripts/verify-service.sh` — a reusable verification script that checks systemd status, HTTP response, and log tail in one shot.