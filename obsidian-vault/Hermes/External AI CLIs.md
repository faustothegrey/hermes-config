# External AI CLIs

## Purpose

Local notes for external coding/agent CLIs that Hermes can orchestrate directly.
Keep high-level pointers in Hermes permanent memory; keep commands, smoke tests, and implementation details here.

## Delegation policy

Hermes should orchestrate external coding CLIs directly when useful:

- Claude Code CLI for durable interactive coding/review workers.
- Antigravity CLI (`agy`) for non-interactive delegated tasks.
- Codex CLI for OpenAI/Codex tasks and quota checks.

Do **not** try to configure Claude Code to delegate to Antigravity; Hermes is the orchestrator.

## Claude Code

### Installed command

```text
/home/fausto/.nvm/versions/node/v24.15.0/bin/claude
```

Observed current version/session banner: `Claude Code v2.1.177`.
Observed account/model: `Claude Pro`, `Sonnet 4.6`.

`tmux` is installed (`3.2a`) and is the preferred transport for interactive Claude Code sessions.

### Working delegation mode

Claude Code is delegable in interactive mode via `tmux`.
Smoke test succeeded: Hermes launched Claude in tmux, accepted workspace trust, sent a prompt, and Claude replied exactly `ciao da Claude`.

Preferred helper script:

```bash
python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  start --session claude-worker --workdir /path/to/repo --name hermes-delegate --yolo

python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  send --session claude-worker --prompt "<self-contained task>"

python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  capture --session claude-worker --lines 160

python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  stop --session claude-worker
```

### Claude CLI options useful for Hermes

Useful native options observed in `claude --help`:

- `--resume <session-id>` / `--continue` / `--session-id <uuid>`
- `--name <name>`
- `--model <model>`
- `--effort low|medium|high|xhigh|max`
- `--permission-mode acceptEdits|auto|bypassPermissions|default|dontAsk|plan`
- `--dangerously-skip-permissions`
- `--worktree`, `--tmux`
- `-p --output-format json`
- `-p --output-format stream-json --include-partial-messages`

### Notes from `claude-wrapper`

`ChrisColeTech/claude-wrapper` is mostly an OpenAI-compatible HTTP wrapper, which is not the useful part for Hermes. Useful ideas:

- Reuse Claude native sessions with `--resume` rather than wrapping everything as stateless API calls.
- Use `claude -p --output-format json` for one-shot bootstrap/status extraction when a TTY is not needed.
- Use native `stream-json` for real non-interactive stream diagnostics; do not copy fake SSE chunking.
- Avoid `echo 'prompt' | claude ...` for large prompts; prefer Python `subprocess(input=...)` or `tmux send-keys -l`.
- Preserve roles/context explicitly in prompts; do not concatenate messages without labels.
- Let Claude use its own CLI tools in a repo/worktree, then have Hermes verify diffs/tests.

## Antigravity

### Installed command

```text
/home/fausto/.local/bin/agy
```

Observed version: `1.0.6`.

Status: authenticated and working in print mode.

Known-good smoke test:

```bash
/home/fausto/.local/bin/agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```

Expected result:

```text
antigravity-ok
```

## Codex

Codex CLI is logged in via ChatGPT on this machine.
For usage/quota checks see [[AI CLI Quotas]].

A reusable Hermes skill exists for Codex quota/status:

```text
~/.hermes/skills/devops/codex-usage-status/
```

It calls Codex app-server JSON-RPC method `account/rateLimits/read` and formats plan, 5-hour, 7-day, credits, and rate-limit state.
