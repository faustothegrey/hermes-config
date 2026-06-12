---
name: github-workflow-operations
description: "GitHub operations umbrella: auth, repositories, issues, PR lifecycle, code review, CI, and repo inspection."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [github, git, gh, issues, pull-requests, code-review, ci, repos]
---

# GitHub Workflow Operations

Use this class-level skill for GitHub work: authentication, repository setup, issues, PRs, reviews, CI checks, releases, and codebase inspection.

## Baseline discovery

Always start by discovering the repo and auth state:

```bash
git status --short
git remote -v
gh --version 2>/dev/null || true
gh auth status 2>/dev/null || true
```

If `gh` is unavailable or unauthenticated, fall back to `git` plus HTTPS/SSH credentials or `GITHUB_TOKEN` with `curl`.

## Authentication

Supported paths:

- `gh auth login` for GitHub CLI workflows.
- HTTPS with `GITHUB_TOKEN`/PAT for REST calls.
- SSH keys for git push/pull.

Do not assume GitHub auth exists just because `git` is installed. Verify before PR/issue/API operations.

## Repository management

Use for cloning, forking, creating repositories, configuring remotes, and managing releases.

Common checks:

```bash
git branch --show-current
git remote get-url origin
gh repo view --json nameWithOwner,defaultBranchRef 2>/dev/null
```

## Issue management

Use `gh issue` first, REST fallback second. For issue creation, collect: title, body, labels, assignees, milestone, and whether the user wants a draft before posting.

Typical operations:

```bash
gh issue list --limit 20
gh issue view <number> --comments
gh issue create --title "..." --body-file issue.md
```

## PR lifecycle

Covers branch creation, commits, push, PR creation, CI monitoring, updating, and merge.

Core flow:

1. Create/confirm branch.
2. Implement and verify locally.
3. Commit with a clear message.
4. Push branch.
5. Open PR with body and test evidence.
6. Watch CI and respond to review comments.
7. Merge only when explicitly requested or policy allows.

## Code review

For PR review, inspect both GitHub context and local diff. Use `gh pr diff`, `gh pr view --comments`, and targeted checkout when needed. Produce findings with severity, file/line, impact, and suggested fix. Inline comments are a side effect; confirm scope before posting them.

## Codebase inspection

For LOC, language mix, file counts, or code/comment ratios, use `pygount` or similar tooling. Keep inspection read-only:

```bash
pip install pygount 2>/dev/null || true
pygount --format=summary .
```

## Verification and reporting

Before reporting completion, include concrete evidence: command outputs, PR/issue URLs or numbers, CI status, and test results. Never rely only on a GitHub web UI assumption or an agent's self-report.
