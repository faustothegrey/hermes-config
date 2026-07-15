# Quota Monitoring — macOS → Linux Porting Session

## Source

`~/Software/scripts-ai/quota-monitoring/` — AI CLI quota monitor (Claude, Codex, Antigravity, OpenRouter).

## What was ported

1. **Hardcoded macOS paths** (`/Users/fausto/...` → `Path.home()` / `~/Software/scripts-ai/...`)
2. **launchd plist** → **systemd unit** (`/etc/systemd/system/quota-monitoring.service`)
3. **Configuration via env vars** — `QUOTA_API_HOST` (default `127.0.0.1`) and `QUOTA_API_PORT` (default `9899`)
4. **Log file** — `~/.hermes/logs/quota-api.log`

## Key changes to api.py

```python
# Before (line 20-21):
sys.path.insert(0, "/Users/fausto/Software/scripts-ai/quota-monitoring")
sys.path.insert(0, "/Users/fausto/Software/scripts-ai/ai-quota-lib")

# After:
from pathlib import Path
_HOME = Path.home()
_SCRIPTS_AI = _HOME / "Software" / "scripts-ai"
sys.path.insert(0, str(_SCRIPTS_AI / "quota-monitoring"))
sys.path.insert(0, str(_SCRIPTS_AI / "ai-quota-lib"))
```

```python
# Before (line 270):
server = HTTPServer(("127.0.0.1", 9899), RouterHandler)

# After:
HOST = os.environ.get("QUOTA_API_HOST", "127.0.0.1")
PORT = int(os.environ.get("QUOTA_API_PORT", "9899"))
server = HTTPServer((HOST, PORT), RouterHandler)
```

## Systemd unit file

Path: `/etc/systemd/system/quota-monitoring.service`

```ini
[Unit]
Description=AI Quota Monitoring API (Claude, Codex, Antigravity, OpenRouter)
Documentation=https://github.com/fausto/scripts-ai/tree/main/quota-monitoring
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=fausto
WorkingDirectory=/home/fausto/Software/scripts-ai/quota-monitoring
ExecStart=/usr/bin/python3 /home/fausto/Software/scripts-ai/quota-monitoring/api.py
Restart=on-failure
RestartSec=10
Environment=QUOTA_API_HOST=0.0.0.0
Environment=QUOTA_API_PORT=9899
StandardOutput=append:/home/fausto/.hermes/logs/quota-api.log
StandardError=append:/home/fausto/.hermes/logs/quota-api.log

[Install]
WantedBy=multi-user.target
```

## Dependencies

- **ai_quota_lib** — Python package in `~/Software/scripts-ai/ai-quota-lib/` (installed manually by user)
- **tmux 3.2a** — needed for heavy usage scrape (Claude/Codex/Antigravity interactive `/usage`). If no tmux sessions exist, the scrape times out (~30-35s per provider).
- **zsh** — NOT available on Linux; `openrouter` fetch fails with `No such file or directory: 'zsh'`. Use `bash` instead.

## API endpoints

| Endpoint | Type | Refresh | Depends on |
|----------|------|---------|------------|
| `GET /tokens` | Claude transcript token totals | ~2 min | `~/.claude/` transcript JSON files |
| `GET /usage` | Usage % for all providers | ~10 min | tmux session for each CLI + OpenRouter REST API |

## Known issues

- **First usage fetch takes ~100s** — all 4 providers run with 30-35s timeouts. During this window, `GET /usage` returns stale cache (or "Not loaded yet" on first-ever cycle).
- **OpenRouter fails on Linux** — `urlopen` tries `zsh -ic 'echo "$OPENROUTER_API_KEY"'` but `zsh` doesn't exist. Fix: change to `bash` or read `OPENROUTER_API_KEY` directly from environment.
- **No tmux sessions → scraped data unavailable** — the scrape functions create their own tmux session if none exists.

## Verification

```bash
sudo systemctl status quota-monitoring.service --no-pager
curl -s http://127.0.0.1:9899/tokens | python3 -m json.tool | head -5
curl -s http://127.0.0.1:9899/usage | python3 -m json.tool | head -10
tail -5 /home/fausto/.hermes/logs/quota-api.log
```