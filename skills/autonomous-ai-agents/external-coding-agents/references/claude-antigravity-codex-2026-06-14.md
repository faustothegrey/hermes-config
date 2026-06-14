# Session notes: Claude Code, Antigravity, and Codex delegation (2026-06-14)

## Context

The user wanted Hermes to delegate work directly to external coding CLIs, especially interactive Claude Code and Antigravity, and to keep implementation detail out of first-level Hermes memory. First-level memory should contain compact pointers; detailed recipes belong in the Obsidian vault and this skill's references/scripts.

## Claude Code delegation

Verified local facts:

- `claude` is installed and authenticated.
- Claude Code banner observed: `Claude Code v2.1.177`, `Claude Pro`, `Sonnet 4.6`.
- `tmux 3.2a` is available.
- Interactive Claude delegation works via tmux.

Smoke test:

1. Start a tmux Claude session with the helper script.
2. Accept workspace trust if the TUI prompts.
3. Send: `Rispondi soltanto con: ciao da Claude`.
4. Expected Claude response: `ciao da Claude`.

Use `scripts/claude_tmux_worker.py` rather than raw tmux when possible.

## Claude Code subscription usage

Claude Code current quota is visible through the interactive TUI command `/usage`, not by asking the model in natural language.

Observed fields from `/usage`:

- current session/window percent and reset time;
- current week percent and reset time;
- usage credits state;
- session token/cost-equivalent telemetry.

Interpretation pitfall:

- If login method is `Claude Pro account` and `Usage credits are off`, the dollar value shown by Claude Code is an API-equivalent estimate, not an extra charge beyond the subscription.
- `Total duration (API)` is model/API time; `Total duration (wall)` is elapsed interactive session time.

## Antigravity delegation

Verified local facts:

- `agy` path: `/home/fausto/.local/bin/agy`.
- Observed version: `1.0.6`.
- Non-interactive print mode works.

Smoke test:

```bash
agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```

Expected output:

```text
antigravity-ok
```

## Codex quota

Codex subscription usage can be read through Codex app-server JSON-RPC method `account/rateLimits/read`. A script already exists in this skill:

```text
scripts/codex_usage_status.py
```

The previously-created narrow `codex-usage-status` skill was consolidated into this umbrella skill so external AI CLI workflows stay class-level.

## Memory hygiene pattern

For these external CLI workflows:

- first-level Hermes memory: keep only a short pointer to Obsidian and the umbrella skill;
- Obsidian vault: store local paths, smoke tests, quota snapshots, interpretation notes;
- skill references/scripts: store reusable recipes and deterministic helpers.
