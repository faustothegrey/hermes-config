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

Some CLIs require a TTY. Use `tmux` rather than raw foreground terminal sessions:

```bash
tmux new-session -d -s coding-worker -x 120 -y 40 'claude'
tmux send-keys -t coding-worker 'Your self-contained task prompt here' Enter
tmux capture-pane -t coding-worker -p
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

- Claude Code can have usage/quota states that only appear in interactive output; inspect the CLI status when calls fail unexpectedly.
- Codex interactive quota/status may not be visible from a single failed command; run the CLI status/login flow when needed.
- Browser/OAuth auth flows often require a real TTY or user intervention. Do not loop blindly on auth failures.

## Verification standard

External agents are collaborators, not sources of truth. Verify with:

- Targeted tests or build commands.
- Static review of diffs.
- Re-running reproduction steps for bugs.
- Confirming any generated artifacts exist and have expected content.

Report concrete commands and results, not merely the worker's final message.
