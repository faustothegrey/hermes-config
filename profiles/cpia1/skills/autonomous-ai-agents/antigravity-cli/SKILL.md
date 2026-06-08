---
name: antigravity-cli
description: "Delegate coding, analysis, and implementation tasks to Google's Antigravity CLI (`agy`) directly from Hermes."
version: 1.0.0
author: Hermes Agent + Fausto
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [Coding-Agent, Antigravity, Google, agy, Delegation, Automation]
    related_skills: [claude-code, codex, opencode, hermes-agent]
---

# Antigravity CLI — Hermes Orchestration Guide

Use this skill when the user asks to use Antigravity, `agy`, Google's Antigravity CLI, an independent coding-agent pass, or when Hermes should compare or offload a bounded coding/review task to an external agent.

The intended topology is:

Hermes parent agent → terminal tool → `agy` CLI

Do not configure Claude Code to call Antigravity unless the user explicitly asks for Claude Code subagent wiring. Hermes should stay the orchestrator: decide whether to call `agy`, run it, inspect the result, verify claims, and report back.

## Known local setup

- Command: `/home/fausto/.local/bin/agy` or `agy` on PATH
- Verified version: `1.0.1`
- Verified authenticated in print mode with output `antigravity-ok`

## Prerequisites / smoke tests

Run these before the first real delegation in a session if auth or PATH may have changed:

```bash
command -v agy
agy --version
agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s
```

If it prints an OAuth URL or times out waiting for authentication, stop and tell the user Antigravity is installed but not authenticated. Do not attempt browser OAuth yourself.

## Preferred mode: non-interactive print mode

For read-only analysis:

```bash
agy -p 'Analyze this repository for <question>. Do not modify files. Return concise findings with file paths.' --print-timeout 10m
```

For implementation:

```bash
agy -p 'Implement <task>. You may edit files. Run relevant tests and report changed files and commands run.' \
  --dangerously-skip-permissions \
  --print-timeout 20m
```

If the task needs access to additional directories, add repeated `--add-dir <path>` flags.

## Prompt construction

Keep the prompt self-contained. Include:

1. User's requested task.
2. Current working directory and relevant file paths.
3. Whether the task is read-only or may edit files.
4. Project conventions from `AGENTS.md`, `CLAUDE.md`, `PROJECT.md`, package manifests, or prior controller inspection.
5. Expected deliverables.
6. Required verification commands, or ask Antigravity to report what it ran.
7. Any known baseline failures so Antigravity does not misattribute them.

## Controller responsibilities

Hermes remains responsible for correctness:

1. Do prerequisite discovery itself when useful: git status, project docs, baseline tests for substantial work.
2. Run `agy` with a bounded timeout.
3. Treat `agy` output as unverified.
4. Inspect diffs/files after `agy` returns.
5. Run relevant tests or checks directly when feasible.
6. Summarize what Antigravity did, what Hermes verified, and any remaining risks.

## Choosing Antigravity vs Claude Code CLI

Prefer Antigravity when:

- The user explicitly asks for Antigravity or `agy`.
- A second independent agent opinion is useful.
- You want a Google/Antigravity-flavored implementation or review pass.
- Claude Code is rate-limited, unavailable, or not ideal for the requested task.

Prefer Claude Code CLI when:

- The task benefits from Claude Code's mature repository-editing workflow, JSON output, session resume, or `--allowedTools` restrictions.
- Existing project conventions mention Claude Code.
- You need structured JSON output from the external agent.

For high-risk or substantial edits, it can be useful to ask one CLI to implement and the other to review, but only when the extra cost/time is justified.

## Pitfalls

- `agy` print mode exits with status 0 even for some auth-timeout messages; inspect stdout for authentication errors.
- Always quote prompts safely. Prefer single quotes around simple prompts, or write a prompt file / use shell-safe quoting for complex prompts.
- `--dangerously-skip-permissions` should only be used when the user has authorized autonomous edits in the working tree.
- Do not assume changed files from `agy` are correct; verify with git diff and tests.
