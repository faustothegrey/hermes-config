# Session Handoff

Last saved: 2026-06-08 11:56:21 CEST

## Continue from here

The user asked to continue exactly from this point after an imminent restart.

Current agreed directive for ScienceClick2:

- Hermes acts as orchestrator, not implementer.
- For ScienceClick2 app changes:
  - Break down/scope the requested work.
  - Delegate implementation entirely to Antigravity CLI.
  - Instruct Antigravity to use the `create-scene` skill.
  - Delegate assessment/review to Claude CLI afterward.
  - Do not verify code changes, tests, or app behavior directly in Hermes.
  - Hermes may only verify orchestration-level completion and service restart outcome.
  - Restart the `butler` service once Antigravity and Claude have both finished.

Important context already stored in Hermes memory:

- ScienceClick2 path: `/home/fausto/Software/ScienceClick2`.
- Runtime server is managed by system service `butler`; do not start duplicate dev servers.
- Antigravity CLI is installed as `/home/fausto/.local/bin/agy`; non-interactive print mode works.
- Claude Code CLI is available; interactive tmux mode is preferred for delegation.

Recent clarification:

- User corrected “carpenter” metaphor: use “orchestrator”.
- “Don’t verify” refers only to code/app changes, not command completion or service restart.
