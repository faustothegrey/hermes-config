# Claude Code usage / quota inspection

Use this when the user asks for Claude Code CLI usage, subscription status, or quota information.

## CLI probes

Auth/subscription identity:

```bash
claude auth status --json
claude auth status --text
```

Non-interactive `/usage` probe:

```bash
claude -p '/usage' --max-turns 1 --output-format json --no-session-persistence
```

The JSON result may contain a `result` like:

```text
You are currently using your subscription to power your Claude Code usage
```

This confirms subscription-backed usage, but may not expose remaining quota, percentage used, or reset time.

## Local token usage from transcripts

Claude Code transcript files live under:

```text
~/.claude/projects/**/*.jsonl
```

Assistant messages can include a `message.usage` object:

```json
{
  "message": {
    "model": "claude-sonnet-4-6",
    "usage": {
      "input_tokens": 3,
      "cache_creation_input_tokens": 306,
      "cache_read_input_tokens": 16797,
      "output_tokens": 123
    }
  }
}
```

Reusable aggregation pattern:

```python
import json, datetime as dt
from pathlib import Path

totals = {
    "input_tokens": 0,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 0,
    "output_tokens": 0,
}
by_model = {}
cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=30)

for path in (Path.home() / ".claude" / "projects").rglob("*.jsonl"):
    for line in path.open(errors="replace"):
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        # timestamp parsing omitted for brevity; filter by cutoff when needed
        msg = obj.get("message") or {}
        usage = msg.get("usage") or {}
        if not usage:
            continue
        model = msg.get("model") or "unknown"
        slot = by_model.setdefault(model, {k: 0 for k in totals})
        for key in totals:
            value = usage.get(key) or 0
            if isinstance(value, (int, float)):
                totals[key] += int(value)
                slot[key] += int(value)
```

## Reporting guidance

- Separate **quota/subscription status** from **historical local token usage**.
- Do not invent percentage remaining or reset time if Claude CLI does not expose it.
- If `/usage` only reports subscription status, say that explicitly.
- Local transcript totals are useful for “how much have I used locally?” but are not the same as provider-side billing/quota counters.
- Use `--no-session-persistence` for the `/usage` probe when you do not want the probe itself to leave an extra transcript entry.
