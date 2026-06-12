---
name: software-development-methods
description: "Software development methods umbrella: planning, spikes, TDD, systematic debugging, code verification, and language debuggers."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [software-development, planning, spike, tdd, debugging, code-review, python, node]
---

# Software Development Methods

Use this class-level skill for process-level software work: planning, throwaway spikes, test-driven development, systematic debugging, verification before commit, and debugger-driven investigation in Python or Node.js.

## Choose the method

| Situation | Method |
|---|---|
| User asks for a plan only | Plan mode: write an actionable markdown plan, do not implement |
| Feasibility unknown | Spike: disposable experiment to learn, then throw away |
| New behavior or bug fix | TDD: red, green, refactor |
| Bug/test failure/production issue | Systematic debugging: root cause before fix |
| Before commit/push/ship | Independent code verification/review |
| Python runtime issue | `pdb` / `debugpy` workflow |
| Node.js runtime issue | `node inspect` / CDP inspector workflow |

## Plan mode

When planning only, inspect read-only as needed and save a concrete markdown plan under `.hermes/plans/`. Do not edit implementation files or run mutating commands.

## Spikes

Use spikes to answer uncertainty that research cannot: compare APIs, validate performance, test feasibility, or build a quick prototype. Keep the code disposable and document what was learned.

## Test-driven development

For behavior changes, write the test first and watch it fail. Then write minimal code to pass and refactor while keeping tests green. If TDD is inappropriate, state why.

## Systematic debugging

No fixes before root cause. Reproduce, gather evidence, narrow the fault, identify the causal mechanism, then patch. Keep symptom-masking fixes out unless explicitly accepted as a temporary mitigation.

## Pre-commit verification

No agent should verify only its own work. Use tests, static checks, diffs, and an independent review pass when appropriate. Fix findings and re-run relevant checks.

## Git update / stash conflict triage

When updating a live checkout with local changes the user may want to preserve but not merge now:

1. Stash first with a descriptive timestamped message, e.g. `git stash push -u -m "pre-update-$(date +%Y%m%d-%H%M%S)"`, then verify `git stash list --max-count=1`.
2. After the update, prefer `git stash apply` over `git stash pop` for the first re-application attempt. If conflicts occur, the original stash remains intact.
3. If conflicts arise and the user asked to be informed before resolution, stop immediately after reporting conflicted files (`git diff --name-only --diff-filter=U`) and do not edit markers.
4. To abandon a conflicted apply while keeping the stash for later, first verify the stash is still present, then realign with upstream using `git reset --hard origin/<branch>` only when the user explicitly wants a clean upstream checkout. Check for untracked files before any cleanup.
5. Final report should include branch, `HEAD` vs `origin/<branch>`, clean/dirty status, and the stash identifier/message that preserves the deferred work.

## Debuggers

- Python: use `breakpoint()`, `python -m pdb`, or `debugpy` for remote/headless attach.
- Node: use `node inspect` for quick REPL debugging or Chrome DevTools Protocol tooling for scriptable breakpoints/scope inspection.

## Reporting standard

Final reports should include: what was investigated, root cause or plan, files changed if any, commands run, test/check outputs, and known remaining risks.
