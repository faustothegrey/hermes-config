# Codex usage / quota inspection

Codex CLI can expose recent usage and quota state through local session JSONL logs.

## Where to look

Default home:

```text
~/.codex
```

Session logs:

```text
~/.codex/sessions/**/*.jsonl
```

The useful records look like:

```json
{
  "type": "event_msg",
  "payload": {
    "type": "token_count",
    "info": {
      "total_token_usage": {
        "input_tokens": 15145,
        "cached_input_tokens": 4480,
        "output_tokens": 14,
        "reasoning_output_tokens": 0,
        "total_tokens": 15159
      },
      "model_context_window": 258400
    },
    "rate_limits": {
      "limit_id": "codex",
      "primary": {
        "used_percent": 2.0,
        "window_minutes": 300,
        "resets_at": 1779872906
      },
      "secondary": {
        "used_percent": 10.0,
        "window_minutes": 10080,
        "resets_at": 1780333405
      },
      "plan_type": "plus"
    }
  }
}
```

## Reusable parser pattern

```python
import json, datetime as dt
from pathlib import Path

best = None
for path in (Path.home() / ".codex" / "sessions").rglob("*.jsonl"):
    for line in path.open(errors="replace"):
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        payload = obj.get("payload") or {}
        if obj.get("type") == "event_msg" and payload.get("type") == "token_count":
            ts = obj.get("timestamp") or ""
            if best is None or ts > best[0]:
                best = (ts, payload)

if best:
    rate_limits = best[1].get("rate_limits") or {}
    primary = rate_limits.get("primary") or {}
    used = primary.get("used_percent")
    remaining = None if used is None else max(0.0, 100.0 - float(used))
```

## Preferred local script

On this machine, the consolidated quota checker is:

```bash
/home/fausto/bin/ai-cli-quotas
```

Use it before hand-rolling JSONL parsing. It reports Codex, Claude Code, and Antigravity usage from the local sources each CLI exposes.

## Fresh-sample workflow for stale Codex resets

Codex quota data in JSONL logs is only as fresh as the latest Codex session. If `resets_at` dates are in the past, or the latest `token_count` timestamp is old, do **not** report the old percentages as current. Generate a fresh sample with the smallest possible Codex call, then rerun the quota script:

```bash
TMP=$(mktemp -d)
cd "$TMP"
git init -q
codex exec 'Reply exactly: OK'
/home/fausto/bin/ai-cli-quotas
```

The tiny session causes Codex to write a new `token_count` event with current `rate_limits` when the CLI/backend exposes them.

## Caveats
## Fresh-sample workflow

Before reporting Codex quota percentages, compare the latest `resets_at` values to the current time. If any reported reset is in the past, treat the local `token_count` event as stale and refresh it with a tiny session:

```bash
TMP=$(mktemp -d)
cd "$TMP"
git init -q
codex exec 'Reply exactly: OK'
```

Then parse `~/.codex/sessions/**/*.jsonl` again. On Fausto's machine, the local aggregator is:

```bash
/home/fausto/bin/ai-cli-quotas
```

Run it after the tiny Codex session when the previous Codex section had stale reset dates.

## Caveats

- The log only reflects the most recent recorded local Codex session. If the latest `token_count` event is old, report its timestamp and refresh with the tiny-session workflow before treating it as current.
- `used_percent` gives a percentage; convert reset epochs with local timezone formatting for user-facing reports.
- Do not infer quota if no `rate_limits` object is present. Report that the local logs do not currently expose a quota sample.
- `codex login status` confirms auth mode but does not itself print detailed quota.
