# AI CLI Quotas

## Policy

For Codex quota, prefer the interactive Codex `/status` screen. Do not rely on stale local log parsing for Codex quota: better no data than stale data.

## Codex

Use a real TTY/tmux session and run `/status`:

```bash
SESSION=codex_status_check
(tmux kill-session -t "$SESSION" 2>/dev/null || true)
tmux new-session -d -s "$SESSION" -x 140 -y 50 'codex'
sleep 8
tmux send-keys -t "$SESSION" '/status' Enter
sleep 8
tmux capture-pane -t "$SESSION" -p -S -200 | tail -120
tmux send-keys -t "$SESSION" C-c || true
tmux kill-session -t "$SESSION" 2>/dev/null || true
```

The status screen shows model, account, 5h limit, weekly limit, and reset times.

Observed 2026-06-12 before peer-mesh work:

- Codex CLI: `v0.137.0`
- model: `gpt-5.5`, reasoning medium
- account: Plus
- 5h limit: 61% left, reset 16:06
- weekly limit: 94% left, reset 19 Jun 11:06

Treat observed quota values as historical only.

## Claude Code

Claude Code can have usage/quota states that only appear in interactive output. Inspect the CLI status/usage in a TTY/tmux session when needed.

## Antigravity

On `agy` 1.0.6, no reliable local token/quota percentages were observed. Use functional smoke tests rather than inferred quota numbers.

Known-good smoke test:

```bash
/home/fausto/.local/bin/agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```
