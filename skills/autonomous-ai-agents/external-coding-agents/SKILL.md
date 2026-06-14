---
name: external-coding-agents
description: "Operate external autonomous coding CLIs: Claude Code, Codex, OpenCode, and similar agent workers."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [coding-agents, claude-code, codex, opencode, delegation, worktrees]
---

# External Coding Agents

Use this class-level skill when delegating implementation, refactors, PR review, or long-running coding work to an external autonomous coding CLI such as Claude Code, Codex, OpenCode, or future equivalents.

## Core orchestration pattern

1. Verify the repository and task scope.
2. Check the target CLI is installed and authenticated.
3. Use an isolated worktree or throwaway branch for side-effecting work.
4. Provide a self-contained prompt with paths, acceptance criteria, and constraints.
5. Capture logs/output and verify resulting changes yourself with tests, diffs, or review.
6. Do not claim success from the worker's self-report alone.

## Choosing a worker

| Worker | Use when | Auth/install notes |
|---|---|---|
| Claude Code | Strong autonomous coding/review, complex repo edits, subagent-friendly work | `npm install -g @anthropic-ai/claude-code`; run `claude` once or set Anthropic auth |
| Codex CLI | OpenAI Codex coding agent, batch fixes, feature branches, PR review | `npm install -g @openai/codex`; use Codex OAuth or `OPENAI_API_KEY`; run inside a git repo |
| OpenCode | Provider-agnostic/open-source agent sessions, long-running TUI/CLI workflows | install `opencode`; configure providers according to OpenCode docs |

## Launching one-shot tasks

Prefer non-interactive CLI mode when available and wrap long runs with Hermes process tracking:

```bash
# Example shape; adapt flags to the installed CLI version.
claude -p "Implement ...; run tests; summarize changes" 

codex exec "Fix ...; run targeted tests; report diff summary"

opencode run "Review this PR for correctness and security"
```

For bounded but long work, use `terminal(background=true, notify_on_complete=true)` so completion is not missed.

## Interactive/TUI workers

Some CLIs require a TTY. Use `tmux` rather than raw foreground terminal sessions.
For Claude Code specifically, this profile has a helper script at `scripts/claude_tmux_worker.py`:

```bash
# Start a durable interactive Claude worker in a repo/worktree.
python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  start --session claude-worker --workdir /path/to/repo --name hermes-delegate --yolo

# Send a self-contained task prompt.
python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  send --session claude-worker --prompt "Implement ...; run tests; summarize changes."

# Inspect progress/output.
python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  capture --session claude-worker --lines 160

# Stop when done.
python3 ~/.hermes/skills/autonomous-ai-agents/external-coding-agents/scripts/claude_tmux_worker.py \
  stop --session claude-worker
```

Raw tmux equivalent:

```bash
tmux new-session -d -s coding-worker -x 140 -y 45 -c /path/to/repo 'claude --name hermes-delegate'
tmux send-keys -t coding-worker -l 'Your self-contained task prompt here'
tmux send-keys -t coding-worker Enter
tmux capture-pane -t coding-worker -p -S -160
```

## Worktree discipline

Use isolated worktrees for parallel or risky work:

```bash
git worktree add ../repo-agent-task -b agent/task-name
```

Give the worker only the intended worktree path. Before merging worker output, inspect:

```bash
git status --short
git diff --stat
git diff
```

## Quota and auth pitfalls

- Claude Code usage/quota is visible in the interactive TUI with `/usage` (shows current session/window percent, weekly percent, reset times, credits state, and per-session token/cost stats). `/status` also has a Usage tab with historical usage stats, but `/usage` is the direct quota/limit view. Do not ask Claude in natural language for account quota: it may say it cannot access account data even though the TUI slash command can show local subscription usage.
- Codex interactive quota/status may not be visible from a single failed command; run the CLI status/login flow when needed.
- To check Codex subscription consumption without opening the TUI, prefer the bundled helper `scripts/codex_usage_status.py`. It starts `codex app-server --listen stdio://` and calls JSON-RPC `account/rateLimits/read`, which returns the ChatGPT-plan Codex bucket (`planType`, 5-hour `primary.usedPercent`, 7-day `secondary.usedPercent`, reset timestamps, credits, and `rateLimitReachedType`).
- Browser/OAuth auth flows often require a real TTY or user intervention. Do not loop blindly on auth failures.

## Notes from `claude-wrapper`

`ChrisColeTech/claude-wrapper` is mainly an OpenAI-compatible HTTP API wrapper, but several implementation ideas are useful for Hermes → Claude CLI delegation:

- Use Claude Code's real session controls rather than API wrapping: `--resume <session-id>`, `--continue`, `--session-id <uuid>`, and interactive sessions in tmux.
- For one-shot bootstrap or status extraction, `claude -p --output-format json` can return structured output including the Claude session id; save that id if a later interactive worker should resume it.
- For non-interactive streaming diagnostics, `claude -p --output-format stream-json --include-partial-messages` is better than fake SSE chunking; the wrapper's HTTP streaming buffers the full response and then chunks it, so do not copy that part for true first-token streaming.
- Avoid constructing commands as `echo 'prompt' | claude ...` for large prompts. Prefer Python `subprocess.run(..., input=prompt)` in non-interactive wrappers, or tmux `send-keys -l` for interactive workers.
- Preserve role/context explicitly in the prompt given to Claude. The wrapper concatenates OpenAI messages without role labels, which is lossy; Hermes prompts should include task, context, constraints, acceptance criteria, and required output format.
- Tool calling in the wrapper is prompt-level JSON, not a robust tool bridge. For Hermes delegation, let Claude use its own tools inside the repo/worktree and have Hermes verify diffs/tests afterward.

## Session-specific references

- `references/claude-antigravity-codex-2026-06-14.md` — verified local delegation details for Claude Code via tmux, Antigravity `agy` print-mode smoke test, Codex quota script consolidation, and Claude `/usage` interpretation.

## Session-specific reference notes

- `references/claude-antigravity-codex-2026-06-14.md` — local smoke tests and operating notes for Claude Code via tmux, Antigravity `agy`, and Codex quota checks.

## Verification standard

External agents are collaborators, not sources of truth. Verify with:


- Targeted tests or build commands.
- Static review of diffs.
- Re-running reproduction steps for bugs.
- Confirming any generated artifacts exist and have expected content.

Report concrete commands and results, not merely the worker's final message.
