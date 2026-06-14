# AI CLI Quotas

## Policy

Keep exact quota percentages as snapshots only. For current values, query the CLI live.

## Codex

Preferred reliable method: Codex app-server JSON-RPC via Hermes skill `codex-usage-status`.

Skill path:

```text
~/.hermes/skills/devops/codex-usage-status/
```

Core mechanism:

- Start `codex app-server --listen stdio://`
- JSON-RPC `initialize`
- JSON-RPC `account/rateLimits/read`

The response includes:

- `rateLimits.planType`
- `primary.usedPercent`, `primary.resetsAt` — rolling 5-hour window
- `secondary.usedPercent`, `secondary.resetsAt` — 7-day window
- `credits`
- `rateLimitReachedType`

Observed 2026-06-14:

- Login: ChatGPT auth OK
- Plan: `plus`
- 5-hour usage: `17% used`
- 7-day usage: `49% used`
- Credits: none / balance `0`
- Rate limited: no

Treat observed values as historical only.

Fallback method: interactive Codex `/status` in tmux can show account/model/quota state if app-server JSON-RPC changes.

## Claude Code

Preferred live method: run `/usage` inside an interactive Claude Code TUI session.

`/usage` shows:

- Current session/window percent and reset time.
- Current week percent and reset time.
- Usage credits state.
- Session token/cost-equivalent stats.

Important interpretation:

- With `Login method: Claude Pro account` and `Usage credits are off`, the dollar cost shown by Claude Code is an API-equivalent estimate/telemetry, not an extra charge beyond the subscription.
- `Total duration (API)` is time spent in model/API calls.
- `Total duration (wall)` is real elapsed interactive session time.

Observed 2026-06-14 via `/usage`:

- Account: Claude Pro
- Model: Sonnet 4.6
- Current session/window: `41% used`, reset `15:59 Europe/Rome`
- Current week: `41% used`, reset `Jun 17, 08:59 Europe/Rome`
- Usage credits: off

Treat observed values as historical only.

## Antigravity

On `agy` 1.0.6, no reliable local token/quota percentages were observed. Use functional smoke tests rather than inferred quota numbers.

Known-good smoke test:

```bash
/home/fausto/.local/bin/agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```
