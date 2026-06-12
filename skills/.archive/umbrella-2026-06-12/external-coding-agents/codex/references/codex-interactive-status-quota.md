# Codex interactive `/status` quota capture

Use this when current Codex quota matters.

## Durable lesson

Codex CLI's interactive `/status` screen is the only acceptable local source for current Plus quota windows on Fausto's setup. Do not parse Codex logs/JSONL for quota data: better no Codex quota data than stale Codex quota data. It shows:

- `5h limit: ... N% left (resets HH:MM)`
- `Weekly limit: ... N% left (resets HH:MM on DD Mon)`

## Robust tmux automation pattern

Codex is a TUI app. Automate it through tmux and a temporary git repo:

```bash
SESSION=codex-status-$$
WORKDIR=$(mktemp -d /tmp/codex-quota-XXXXXX)
git -C "$WORKDIR" init -q
tmux new-session -d -s "$SESSION" -x 140 -y 45 -c "$WORKDIR" codex
sleep 5
tmux send-keys -t "$SESSION" Enter     # accept trust prompt if present
sleep 8                                  # wait for model/MCP startup; early Enter can be ignored
tmux send-keys -t "$SESSION" '/status'
sleep 1
tmux send-keys -t "$SESSION" Enter
sleep 6
tmux capture-pane -t "$SESSION" -p -S -160
tmux kill-session -t "$SESSION"
rm -rf "$WORKDIR"
```

Important detail: after Codex startup, sending `'/status'` and `Enter` in the same `tmux send-keys` call can leave the command in the input box without executing on some runs. Send the text, wait briefly, then send `Enter` separately.

## Parser pattern

Strip ANSI/control characters, then parse lines like:

```text
5h limit:     [████████████░░░░░░░░] 59% left (resets 13:04)
Weekly limit: [█████████████░░░░░░░] 66% left (resets 10:07 on 12 Jun)
```

Convert `left_percent` to `used_percent = 100 - left_percent` for reporting.

Regex shape:

```python
r"5h\s+limit:\s*(?:\[[^\]]*\]\s*)?([0-9]+)%\s+left\s+\(resets\s+([^\)]+)\)"
r"Weekly\s+limit:\s*(?:\[[^\]]*\]\s*)?([0-9]+)%\s+left\s+\(resets\s+([^\)]+)\)"
```

## Updating `/home/fausto/bin/codex-quota` and `/home/fausto/bin/ai-cli-quotas`

When the user asks for current Codex quotas, prefer the Codex-only script `/home/fausto/bin/codex-quota`. The combined aggregator `/home/fausto/bin/ai-cli-quotas` may still include a Codex section. Both scripts should automate interactive `/status` for Codex. If `/status` cannot be captured, they should show no Codex quota values.

Useful implementation details:

- Shared quota helpers live in `/home/fausto/bin/ai_quota_lib.py`.
- Resolve binaries robustly for non-login shells: check `PATH`, `~/.local/bin`, `~/bin`, and `~/.nvm/versions/node/*/bin`.
- Keep Codex data sourced only from `/status`; do not preserve or print Codex log-derived quota/token output.
- Verify with `python3 -m py_compile /home/fausto/bin/ai_quota_lib.py /home/fausto/bin/codex-quota /home/fausto/bin/ai-cli-quotas` and real script runs.
