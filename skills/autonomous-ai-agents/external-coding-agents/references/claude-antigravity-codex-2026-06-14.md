# Claude / Antigravity / Codex local delegation notes — 2026-06-14

Session-specific details distilled for future Hermes external-agent delegation.

## Claude Code

Local Claude Code is installed and usable via TTY/tmux. A smoke test launched an interactive Claude session in tmux, accepted workspace trust, sent an Italian prompt, and got the exact response:

```text
ciao da Claude
```

Useful local facts observed:

- Command: `/home/fausto/.nvm/versions/node/v24.15.0/bin/claude`
- Claude Code banner observed: `v2.1.177`
- Account/model banner observed: `Claude Pro`, `Sonnet 4.6`
- `tmux` available: `3.2a`

Preferred Hermes orchestration pattern:

```bash
python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  start --session claude-worker --workdir /path/to/repo --name hermes-delegate --yolo

python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  send --session claude-worker --prompt "<self-contained task>"

python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  capture --session claude-worker --lines 160
```

Claude Code `/usage` is the direct subscription/quota view. It showed:

- current session/window percent + reset time;
- current week percent + reset time;
- usage credits state;
- per-session token/cost-equivalent stats.

Interpretation: when login is `Claude Pro account` and usage credits are off, dollar cost shown in `/usage` is an API-equivalent estimate/telemetry, not a separate charge beyond subscription. `Total duration (API)` is model/API time; `Total duration (wall)` is elapsed interactive time.

## Antigravity

Antigravity CLI `agy` is installed and works in print mode.

Observed:

- Command: `/home/fausto/.local/bin/agy`
- Version: `1.0.6`

Known-good smoke test:

```bash
/home/fausto/.local/bin/agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```

Expected output:

```text
antigravity-ok
```

## Codex

Codex quota is best checked via the `codex-usage-status` skill/script using Codex app-server JSON-RPC `account/rateLimits/read`, not by parsing stale logs.

Observed shape returned plan, 5-hour usage, 7-day usage, credits, and rate-limit status. Treat exact percentages as snapshots only.
