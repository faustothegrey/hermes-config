# External AI CLIs

## Purpose

Local notes for external coding/agent CLIs that Hermes can orchestrate directly.

## Installed CLIs

### Claude Code

```text
/home/fausto/.nvm/versions/node/v24.15.0/bin/claude
```

Observed version: `2.1.154`.

`tmux` is installed (`3.2a`) and useful for interactive Claude Code sessions.

Operational note:

- On this setup, Claude Code CLI is delegable in interactive mode via `tmux`.
- `claude` starts the TUI.
- After workspace trust, it responds correctly to real prompts.
- Prefer this interactive/tmux mode for Claude delegation.
- `claude -p` print mode still needs separate smoke testing before relying on it.

### Antigravity

```text
/home/fausto/.local/bin/agy
```

Observed version: `1.0.6`.

Status: authenticated and working in print mode.

Known-good smoke test shape:

```bash
/home/fausto/.local/bin/agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```

Expected result:

```text
antigravity-ok
```

User preference: Hermes should orchestrate external coding CLIs directly, delegating to Claude Code CLI or Antigravity CLI when suitable. Do not try to configure Claude Code to delegate to Antigravity.

### Codex

Codex CLI is logged in via ChatGPT on this machine.

For usage/quota checks see [[AI CLI Quotas]].
