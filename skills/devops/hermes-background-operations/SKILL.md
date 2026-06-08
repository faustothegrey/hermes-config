---
name: hermes-background-operations
description: "Operate Hermes durable background systems: gateway services, messaging-platform setup, cron watchdogs, reminders, and script-only scheduled notifications."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hermes, gateway, cron, systemd, watchdogs, reminders, telegram, discord, voice, messaging, automation]
    related_skills: [hermes-agent]
---

# Hermes Background Operations

Use this skill when the user asks to run Hermes outside the foreground CLI: Gateway as a long-lived service, messaging-platform integrations, durable cron jobs, script-only watchdogs, recurring reminders, voice/text gateway operation, or background notification workflows.

Load the protected `hermes-agent` skill first for canonical current commands. This skill adds operational playbooks, decision criteria, and pitfalls learned from setup sessions.

## Choose the right durable mechanism

| Need | Prefer | Why |
|---|---|---|
| Messaging platforms, Telegram/Discord/Slack/etc. | `hermes gateway ...` as a user service | Keeps adapters online and receives inbound events. |
| Recurring or one-shot reminders/checks | `cronjob` / `hermes cron` | Durable scheduled runs with delivery and retry semantics. |
| Mechanical threshold/watchdog alert | `cronjob(no_agent=True, script=...)` | Cheap, deterministic, and silent when there is nothing to report. |
| Long bounded local command (build/test/deploy) | `terminal(background=True, notify_on_complete=True)` | Process output is tracked and one completion notice is sent. |
| Long-lived dev server/daemon inside a task | `terminal(background=True)` with rare `watch_patterns` only for readiness | The process is expected not to exit. |

## Gateway service operations

Use when the user asks to run Hermes Gateway as a background/system service, troubleshoot gateway startup, or finish messaging-platform integration.

### Restarting an existing systemd service on the user's machine

Use this pattern when the user asks to restart a named background service such as an app/dev-server service, not just Hermes Gateway:

1. Discover whether the unit is a user service or a system service before acting:
   - `XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user list-units --all '<name>*' --no-pager`
   - `systemctl list-units --all '<name>*' --no-pager`
   - Also check `list-unit-files` if no active unit is found.
2. Restart the unit in the scope where it actually exists:
   - user unit: `XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user restart <unit>`
   - system unit: `sudo systemctl restart <unit>`
3. Verify immediately with `systemctl is-active <unit>` and `systemctl status <unit> --no-pager --lines=20`.
4. Wait a few seconds and verify again so services that crash just after startup are caught.
5. Report concrete evidence from status/logs: active state, main process, app-ready lines, URLs/ports if the service logs them, and any non-fatal warnings separately from blockers.

1. Discover the actual Hermes executable instead of assuming root's PATH:
   - `command -v hermes`
   - `readlink -f $(command -v hermes)`
   - If `~/.local/bin/hermes` is a wrapper, inspect it to find the venv-backed executable.
2. Prefer a user systemd service unless the user explicitly needs a root-managed unit:
   - `~/.config/systemd/user/hermes-gateway.service`
   - `systemctl --user daemon-reload`
   - `systemctl --user enable --now hermes-gateway.service`
3. In non-login or agent-run shells, `systemctl --user` may fail because `DBUS_SESSION_BUS_ADDRESS` and `XDG_RUNTIME_DIR` are not set. If `/run/user/$(id -u)` exists, prefix commands with:
   - `XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user ...`
4. For services that should survive SSH logout/reboot, check linger and ask/run as appropriate:
   - `loginctl show-user "$USER" -p Linger`
   - `sudo loginctl enable-linger $USER`
5. Put absolute paths in unit files. Do not rely on root or systemd inheriting the user's shell PATH.
6. Verify service health and logs:
   - `hermes status --all`
   - `systemctl --user status hermes-gateway.service --no-pager`
   - `journalctl --user -u hermes-gateway.service -f`

### User service template

Use absolute paths discovered from the target machine.

```ini
[Unit]
Description=Hermes Agent Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/home/USER
Environment=HOME=/home/USER
Environment=HERMES_HOME=/home/USER/.hermes
Environment=PATH=/home/USER/.local/bin:/home/USER/.hermes/hermes-agent/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/home/USER/.local/bin/hermes gateway run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

If Hermes' own installer creates a more specific service command such as `python -m hermes_cli.main gateway run --replace`, preserve it unless it is broken; only patch concrete issues.

## Messaging-platform setup checklists

### Telegram

1. Confirm `TELEGRAM_BOT_TOKEN` exists in `~/.hermes/.env` without printing it.
2. Validate the token via Telegram `getMe` if needed and report only bot id/username, never the token.
3. Check access control:
   - `TELEGRAM_ALLOWED_USERS=<numeric Telegram user IDs>`
   - `TELEGRAM_HOME_CHANNEL=<DM user ID or chat/channel ID>`
   - Optional open testing only when the user explicitly chooses it: `GATEWAY_ALLOW_ALL_USERS=true`.
4. If there are no recent updates from the bot, do not guess the user's ID. Tell the user to message `@userinfobot` or message their bot once, then use the numeric ID.
5. After changing `.env`, restart gateway and verify status/logs.

### Discord text and voice

1. Clarify that a Discord "server" is a Discord-hosted workspace/community, not a local server process. The only local/hosted service needed is Hermes Gateway running on the user's PC/VPS.
2. Do not ask the user to paste Discord bot tokens or other secrets into chat. Have the user create the bot/token in Discord Developer Portal and enter it directly on the machine where Hermes runs.
3. Bot creation flow:
   - Discord Developer Portal → Applications → New Application.
   - Bot → create/reset token; keep it off chat/logs.
   - Privileged Gateway Intents: enable **Message Content Intent**; enable Server Members Intent only if needed; Presence Intent is usually unnecessary.
   - OAuth2 → URL Generator: select `bot` and `applications.commands`.
   - Minimum permissions: View Channels, Send Messages, Read Message History, Connect, Speak. Administrator can be used temporarily for first setup, then tightened.
   - Open the generated invite URL, select the user's Discord server, and authorize the bot.
4. Recommend a text channel such as `#hermes-chat` and a voice channel like `Hermes Voice` for simple use.
5. After the user enters the token locally, configure/verify Discord in Hermes Gateway without printing secrets, restart the gateway, then test text first and voice second.

## Voice interaction playbook

Use when the user wants voice-to-voice, hands-free, or "viva voce" interaction through Hermes.

1. Load `hermes-agent` first for canonical STT/TTS and `/voice` command docs.
2. Match the channel to the interaction style:
   - **Telegram**: asynchronous voice-message loop. User sends a voice note; Hermes transcribes it and can reply with TTS. Good mobile UX, but not continuous listening.
   - **CLI voice mode**: local PC microphone loop with `Ctrl+B`, silence detection, STT, and spoken replies. Good for hands-free work at the computer.
   - **Discord voice channel**: closest built-in option for live bidirectional conversation; Hermes can join a voice channel, listen, detect silence, transcribe, reason/use tools, and speak back.
   - **Phone wake-word**: requires separate Android/app automation outside Telegram; Telegram Bot API cannot start/stop the user's microphone.
3. For Discord voice, verify readiness across gateway status, bot channel permissions, Discord voice dependencies, `ffmpeg`, Opus, STT, and TTS before saying it is ready. See `references/discord-voice-readiness.md`.
4. Give the immediate activation path first: user joins the voice channel, then sends `/voice join` or `/voice channel` in the paired text channel. Do not imply startup auto-join unless a real auto-join feature/config is present and verified.
5. If the user wants an always-on or quick-trigger Discord voice room, treat it as a gateway feature/config change: add/verify `discord.voice_auto_join`, bind it to the paired text channel, tune idle timeout/reconnect behavior, restart gateway, and verify by logs plus Discord API/state. For text-triggered joins such as `voce`, prefer a short initial idle auto-leave guard (`text_trigger_initial_activity_timeout`) so Hermes exits again if nobody speaks right after it joins. See `references/discord-voice-autojoin-implementation.md`.
6. Do not default Discord voice auto-join to permanent listening. Explain the resource/privacy tradeoff first: the idle voice connection is light, but continuous receive/STT can consume CPU/GPU/API credits. Prefer manual `/voice join`, disabled auto-join, text-triggered joins with an initial idle guard, or a normal idle timeout unless the user explicitly accepts always-on behavior.
7. To disable a local auto-join patch safely, use `hermes config set discord.voice_auto_join.enabled false`, `hermes config set discord.voice_auto_join.reconnect false`, and `hermes config set discord.voice_auto_join.disable_timeout false`, then `hermes gateway restart` and verify service status/config. Do not edit protected `~/.hermes/config.yaml` directly via file tools when the config CLI can do it.
8. For Telegram voice replies, use `/voice on`, `/voice tts`, or `/voice off` in the chat when possible.
9. If selecting a TTS voice for an Italian user, Edge TTS has no-key Italian voices such as `it-IT-ElsaNeural`; restart/sync the gateway after runtime config changes.

## Updating Hermes with local gateway/source patches

Use when the user asks to update Hermes itself while preserving local commits or uncommitted changes, especially local gateway/Discord voice patches.

1. Load the protected `hermes-agent` skill first for the current update command and flags.
2. Inspect current branch, `git status --short`, local commits not in `origin/main`, and ahead/behind counts before changing anything.
3. Preserve local work before switching branches or running `hermes update`:
   - create a timestamped backup branch at the current `HEAD`;
   - write `git diff` and `git diff --cached` patch files under `~/.hermes/backups/`;
   - stash uncommitted/untracked work and record the exact stash commit/ref.
4. Update from clean `main` with `hermes update --backup --yes` unless the user needs interactive prompts.
5. Create a new branch from the updated code, cherry-pick the local commits, then apply the recorded stash. Keep the stash until tests pass and the user confirms.
6. Verify with `git status`, `hermes --version`, and task-specific tests, then restart the gateway/CLI runtime.
7. If the user asks for step-by-step control, stop after each major phase and report exact recovery handles before proceeding.

Detailed command sequence: `references/hermes-update-with-local-patches.md`.

## Approval / YOLO mode for background operation

Use only when the user explicitly asks for persistent no-confirmation command execution.

1. Load `hermes-agent` first for canonical approval-mode docs.
2. Set approval mode with the CLI command exactly as a normal unquoted value:
   - `hermes config set approvals.mode off`
   - Do **not** pass shell-embedded quotes such as `"'off'"`; that can serialize as a literal value like `'''off'''` instead of the intended `off`.
3. For a dedicated/trusted agent machine where the user asks for "all grants" / maximum autonomy, also consider these explicit knobs, then verify they match the user's intent:
   - `hermes config set approvals.cron_mode approve` — cron runs may execute flagged commands without an interactive user.
   - `hermes config set security.tirith_enabled false` — disables Tirith pre-exec scanner warnings.
   - `hermes config set hooks_auto_accept true` — auto-accepts shell hooks.
   - `hermes config set browser.allow_private_urls true` and `hermes config set security.allow_private_urls true` — allow local/private URL access.
   - `hermes tools enable <toolset>` for any disabled toolsets the user explicitly wants available.
4. Verify the actual serialized YAML, not just command output:
   - Inspect `~/.hermes/config.yaml` around `approvals:`, `security:`, `browser:`, and `agent.disabled_toolsets`.
5. If the config writer serializes `approvals.mode` as YAML boolean `false` or over-quoted text, rewrite the config through a YAML-aware script so the parsed value is the string `"off"`, then re-read it with `yaml.safe_load` to confirm.
6. Restart the gateway after config changes that affect Telegram/Discord/runtime behavior:
   - `hermes gateway restart`
   - `hermes gateway status`
7. Remind the user that `approvals.mode: off` bypasses command confirmation but does not grant root by itself; sudo still depends on Hermes sudo configuration and credentials, and Hermes may still keep hardline catastrophic-command blocks that YOLO cannot bypass.

## Scheduled watchdogs and reminders

Use when the user asks Hermes to monitor something asynchronously, send a reminder, run a recurring check, or notify before a predictable system event.

### Core pattern

1. Prefer Hermes `cronjob` for durable async checks instead of background terminal processes.
2. For mechanical checks that produce fixed alert text, use `no_agent=True` with a script:
   - Non-empty stdout is delivered verbatim.
   - Empty stdout is silent.
   - Non-zero exit sends an error alert.
3. Keep scripts self-contained and idempotent.
4. Store a small state file under `~/.hermes/state/` when duplicate alerts are possible.
5. Use `deliver='origin'` unless the user explicitly asks for another channel.
6. Verify after creation/update with `cronjob(action='list')`.

### Cadence guidance

- Do not poll every minute by default. Choose the coarsest cadence that still catches the event reliably.
- For predictable events on a 10-minute boundary, `*/10 * * * *` is usually enough.
- If the user asks for an initial/startup check, run the script once manually immediately after creating/updating the job, then schedule the recurring cadence.
- For long-running user work on this machine, remember the daily reboot windows at 00:00, 06:00, 12:00, and 18:00 and avoid starting long tasks shortly before them.

### Nightly tasks

When this user says "nightly task", treat it as a bounded overnight work window, not merely "run sometime at night":

1. Valid local-time window: start no earlier than 00:30 and stop no later than 05:50.
2. Keep the 00:00 restart and 06:00 restart buffers clear: do not start work immediately after midnight or run into the 10 minutes before 06:00.
3. For cron jobs, prefer a start schedule like `30 0 * * *`, but put the hard-stop rule in the prompt/script because cron start time alone does not enforce stop time.
4. For LLM-driven cron, include: "Work only during 00:30–05:50 local time. If the task is not finished by 05:50, stop, checkpoint/save state, summarize remaining work, and do not continue." 
5. For long or uncertain work, make it checkpointable and resumable across multiple nights. Do not begin a subtask if it cannot reasonably checkpoint before 05:50.
6. For script/worker-based nightly jobs, add an explicit wall-clock guard that checks local time before each unit of work and exits cleanly before 05:50.

See `references/nightly-task-window.md` for a reusable prompt/script pattern.

### Watchdog script shape

A good script:

- Reads current state.
- Determines whether an alert is due.
- Prints exactly one concise message when action is needed.
- Prints nothing otherwise.
- Records what it already notified about to avoid repeats.
- Avoids fragile or dangerous shell strings when scanning for reboot/shutdown commands; use Python file reads and regexes where possible.

### Example: reboot pre-warning

See `references/reboot-prewarning-watchdog.md` for the pattern used to warn Hermes 10 minutes before known/system-scheduled reboot windows.

Key points:

- Scan accessible crontabs for reboot-like schedules when possible.
- Add a known-schedule fallback if the user has stated fixed reboot windows.
- Schedule every 10 minutes rather than every minute when the warning time is aligned to 10-minute boundaries.
- Run once immediately after setup/update as a startup/initial check.

## Pitfalls

- A valid Telegram bot token is not enough. Hermes Gateway may still deny all messages if no allowlist is configured.
- Do not default to `GATEWAY_ALLOW_ALL_USERS=true` or `approvals.mode: off` for convenience. Prefer a Telegram allowlist and normal approval prompts unless the user explicitly chooses open access / YOLO mode.
- When enabling persistent YOLO mode, verify the actual config file after `hermes config set`; some values may be coerced by YAML parsing/serialization and need a literal-string patch.
- Do not save or print bot tokens in summaries. Redact secrets and mention only whether they are present/valid.
- Some systemd keys are version-dependent. If `systemctl status` reports `Unknown key name`, patch/remove only those unsupported keys and run `systemctl --user daemon-reload`.
- `systemd-analyze --user verify` may fail in an agent/non-login environment even when the unit works; prefer actual `systemctl --user status` and journal verification when the user manager is running.
- Do not create LLM-driven cron jobs for simple threshold/watchdog alerts; script-only jobs are cheaper, quieter, and more deterministic.
- Do not spam the user: empty stdout should be the normal path.
- If a cron job must survive a reboot, rely on Hermes cron/gateway/service operation rather than a terminal background process.

## References

- `references/telegram-systemd-setup.md` — worked Hermes Gateway + Telegram setup where root PATH lacked `hermes`, user systemd needed `XDG_RUNTIME_DIR`, and Telegram required an allowlist/home channel.
- `references/persistent-yolo-mode.md` — enabling permanent no-confirmation command execution for Hermes/Gateway and verifying config serialization.
- `references/voice-channel-options.md` — voice-channel decision matrix: Telegram voice notes + TTS, CLI continuous voice mode, Discord voice channels, and why Telegram bots cannot do wake-word/continuous phone microphone capture.
- `references/discord-gateway-setup.md` — Discord server/bot setup handoff, safe secret-handling guidance, required bot intents/permissions, and recommended text/voice channel layout.
- `references/discord-voice-readiness.md` — readiness checklist and user-facing activation flow for live Discord voice, including manual `/voice join` versus optional startup auto-join feature shape.
- `references/discord-voice-autojoin-implementation.md` — implementation and verification notes for an always-on Discord voice room: startup auto-join, text-channel binding, idle-timeout handling, reconnect loop, and rollback trail.
- `references/reboot-prewarning-watchdog.md` — script-only cron watchdog pattern for warning before scheduled reboot windows.
- `references/hermes-update-with-local-patches.md` — preserving local Hermes source commits/uncommitted patches while updating upstream `main` and rebuilding the patched branch.
- `references/nightly-task-window.md` — this user's 00:30–05:50 local-time nightly-task window, including cron prompt text and script guard pattern.
