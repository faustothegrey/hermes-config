# ScienceClick2 create-scene orchestration with Antigravity

Use this when Fausto asks Hermes to create or modify a ScienceClick2 scene under the current orchestrator workflow.

## Controller role

Hermes should not implement or directly verify code/app behavior. Hermes should:

1. Read project controller context if needed (`AGENTS.md`, `PROJECT.md`, current `git status`).
2. Scope the scene request into a clear self-contained prompt.
3. Delegate implementation entirely to Antigravity CLI (`agy`).
4. Tell Antigravity to use the repository `create-scene` skill (`skills/create-scene/skill.md`).
5. Delegate assessment to Claude Code afterward.
6. Restart the `butler` service after Antigravity and Claude have finished.
7. Verify only orchestration-level facts: commands completed, assessment returned, and service is active.

## Prompt details that worked

Include in the Antigravity prompt:

- Repository path: `/home/fausto/Software/ScienceClick2`.
- User topic and a controller-confirmed scene direction if the user already gave enough detail.
- Reminder to read `AGENTS.md` and `PROJECT.md`.
- Reminder to use the `create-scene` skill.
- Existing modified/untracked files to avoid, from `git status --short --branch`.
- Scene ID suggestion when appropriate.
- A2-level vocabulary requirement.
- Required deliverable report: scene ID, files created/changed, term list, checks run, caveats.

Example implementation command pattern:

```bash
agy -p "$(cat /tmp/scienceclick2-agy-create-scene.txt)" \
  --dangerously-skip-permissions \
  --print-timeout 20m
```

## Claude assessment pass

Claude Code can assess read-only via interactive tmux on Fausto's setup. Prompt it to inspect the new `config.json` and `scene.png`, keep the report concise and in Italian, and return:

1. Topic match.
2. Config validity.
3. Term/translation suitability.
4. Drop target plausibility/spacing.
5. Caveats.
6. Final verdict: acceptable / needs fixes.

If Claude asks permission for safe read-only shell inspection, approve only the needed read commands. Do not ask Claude to edit unless the user explicitly requests a fix pass.

## Service restart

After both delegations finish:

```bash
sudo -n systemctl restart butler && systemctl is-active butler
```

A direct `systemctl restart butler` may fail with interactive authentication; the durable pattern is to retry non-interactively with `sudo -n` and report the final service state.
