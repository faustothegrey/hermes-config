# External CLI subagents for Claude Code

Use this pattern when the user wants Claude Code to delegate to another autonomous CLI agent (for example `agy`, `codex`, `opencode`, or a local company agent).

## Verification sequence

1. Check the external CLI is on PATH and can show version/help:
   - `command -v <cli>`
   - `<cli> --version || true`
   - `<cli> --help`

2. Run a tiny non-interactive smoke test before registering the agent:
   - `<cli> -p 'Reply with exactly: <tool>-ok' --print-timeout 60s`

3. Interpret authentication/setup prompts carefully:
   - If the CLI prints an OAuth/login URL or waits for credentials, the binary is installed but not yet authenticated.
   - Do not record this as a durable tool failure; ask the user to complete auth, then rerun the same smoke test.
   - Once the exact expected string is returned, the CLI is authenticated and usable.

4. Create a Claude Code user agent under:
   - `~/.claude/agents/<agent-name>.md`

5. Verify Claude Code sees it:
   - `claude agents --setting-sources user`
   - Optional: `claude -p 'Do not use tools. In one sentence, confirm whether the user agent named <agent-name> is available to delegate to in this Claude Code session.' --max-turns 1 --output-format json`

## Agent file template

```markdown
---
name: <agent-name>
description: Delegate coding, analysis, or implementation tasks to <External CLI> via the `<cli>` command.
model: sonnet
tools: [Bash, Read]
---

You are a delegation wrapper for `<External CLI>` (`<cli>`). Invoke it as an external autonomous coding agent and report its result back to the main Claude Code conversation.

When invoked:
1. Confirm `<cli>` is available: `command -v <cli> && <cli> --version`.
2. Run from the current project directory using non-interactive print mode.
3. Keep the prompt self-contained: task, file paths, constraints, deliverables, and whether edits are allowed.
4. Treat the external agent's output as unverified; summarize the command run, success/failure, claimed file changes, and verification still needed.
5. If authentication is required or times out, stop and report that the CLI is installed but not authenticated.
```

## Antigravity (`agy`) example

Smoke test:

```bash
agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```

Implementation invocation:

```bash
agy -p 'Implement <task>. You may edit files. Run relevant tests and report changed files and commands run.' \
  --dangerously-skip-permissions \
  --print-timeout 20m
```

If extra workspace directories are needed, add repeated `--add-dir <path>` flags.