# Claude Code: diagnosing interactive vs print-mode auth

Use this when `claude -p ...` fails with an auth error but it is unclear whether Claude Code itself is logged in.

## Controlled interactive probe

Launch Claude Code in a disposable tmux session, capture the first screen, then kill it. This avoids leaving an interactive TUI running.

```bash
SESSION=claude-auth-check-$$
tmux new-session -d -s "$SESSION" -x 140 -y 40 'cd /path/to/project 2>/dev/null || cd ~; claude'
sleep 5
tmux capture-pane -t "$SESSION" -p -S -80 || true
tmux kill-session -t "$SESSION" || true
```

If the captured screen is the workspace trust prompt, that is not an auth prompt:

```text
Accessing workspace:
/path/to/project

Quick safety check: Is this a project you created or one you trust?
❯ 1. Yes, I trust this folder
  2. No, exit
```

To check what appears after trust, repeat in a fresh tmux session and press Enter for the default `Yes, I trust this folder` before capturing:

```bash
SESSION=claude-auth-check-after-trust-$$
tmux new-session -d -s "$SESSION" -x 140 -y 40 'cd /path/to/project 2>/dev/null || cd ~; claude'
sleep 3
tmux send-keys -t "$SESSION" Enter
sleep 8
tmux capture-pane -t "$SESSION" -p -S -120 || true
tmux kill-session -t "$SESSION" || true
```

A normal interactive prompt after trust looks like:

```text
Claude Code vX.Y.Z
Sonnet ... · Claude API
~/project

❯ Try "refactor <filepath>"
```

## Interpretation

- Workspace trust prompt = project safety confirmation, not login/authentication.
- Normal TUI prompt after accepting trust = interactive Claude Code can start.
- If `claude -p` still returns `401 Invalid authentication credentials`, treat it as a print-mode/auth-path issue and continue diagnosis with `claude auth status --text`, `claude doctor`, environment inspection, and Claude Code config review rather than assuming the interactive login is absent.

## Cleanup rule

Always kill the tmux session after the probe unless you intentionally want to keep the interactive Claude session alive.
