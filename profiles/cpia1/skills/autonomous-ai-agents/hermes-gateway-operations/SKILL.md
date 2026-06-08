---
name: hermes-gateway-operations
description: "Operate Hermes Gateway as a service and finish messaging-platform setup, especially systemd user services, Telegram allowlists/home channels, and Discord bot/voice-channel setup."
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hermes, gateway, systemd, telegram, discord, voice, service, messaging]
    related_skills: [hermes-agent]
---

# Hermes Gateway Operations

Use this skill when the user asks to run Hermes Gateway as a background/system service, troubleshoot gateway startup, or finish a messaging-platform integration such as Telegram.

This skill complements the protected `hermes-agent` skill. Load `hermes-agent` first for canonical commands and current CLI docs, then use this skill for the operational playbook and pitfalls learned from real setup sessions.

## Service setup playbook

1. Discover the actual Hermes executable instead of assuming root's PATH:
   - `command -v hermes`
   - `readlink -f $(command -v hermes)`
   - If `~/.local/bin/hermes` is a wrapper, inspect it to find the venv-backed executable.
2. Prefer a user systemd service for Hermes Gateway unless the user explicitly needs a root-managed unit:
   - `~/.config/systemd/user/hermes-gateway.service`
   - `systemctl --user daemon-reload`
   - `systemctl --user enable --now hermes-gateway.service`
3. In non-login or agent-run shells, `systemctl --user` may fail because `DBUS_SESSION_BUS_ADDRESS` and `XDG_RUNTIME_DIR` are not set. If `/run/user/$(id -u)` exists, prefix commands with:
   - `XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user ...`
4. For services that should survive SSH logout/reboot, check linger and ask/run as appropriate:
   - `loginctl show-user "$USER" -p Linger`
   - `sudo loginctl enable-linger $USER`
5. Put absolute paths in the unit. Do not rely on root or systemd inheriting the user's shell PATH.
6. Verify service health and logs:
   - `hermes status --all`
   - `systemctl --user status hermes-gateway.service --no-pager`
   - `journalctl --user -u hermes-gateway.service -f`

## User service template

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

## Telegram setup checklist

1. Confirm token exists without printing it:
   - Check `TELEGRAM_BOT_TOKEN` in `~/.hermes/.env`.
2. Validate the token via Telegram `getMe` if needed and report only bot id/username, never the token.
3. Check access control:
   - `TELEGRAM_ALLOWED_USERS=<numeric Telegram user IDs>`
   - `TELEGRAM_HOME_CHANNEL=<DM user ID or chat/channel ID>`
   - Optional open testing only when the user explicitly chooses it: `GATEWAY_ALLOW_ALL_USERS=true`.
4. If there are no recent updates from the bot, do not guess the user's ID. Tell the user to message `@userinfobot` or message their bot once, then use the numeric ID.
5. After changing `.env`, restart gateway and verify status/logs.

## Discord setup checklist

Use when the user wants to add Discord text or voice channels to an existing Hermes Gateway.

1. Clarify that a Discord "server" is a Discord-hosted workspace/community, not a local server process. The only local/hosted service needed is Hermes Gateway running on the user's PC/VPS.
2. Do not ask the user to paste Discord bot tokens or other secrets into chat. Have the user create the bot/token in Discord Developer Portal and enter it directly on the machine where Hermes runs, e.g. in `~/.hermes/.env` or through the Hermes gateway setup flow.
3. Bot creation flow to guide the user through:
   - Discord Developer Portal → Applications → New Application.
   - Bot → create/reset token; keep it off chat/logs.
   - Privileged Gateway Intents: enable **Message Content Intent**; enable Server Members Intent only if needed; Presence Intent is usually unnecessary.
   - OAuth2 → URL Generator: select `bot` and `applications.commands`.
   - Minimum permissions: View Channels, Send Messages, Read Message History, Connect, Speak. Administrator can be used temporarily for first setup, then tightened.
   - Open the generated invite URL, select the user's Discord server, and authorize the bot.
4. Server/channel layout: for simple Hermes use, recommend a general template such as Study Group over Gaming, then create a text channel like `#hermes-chat` and a voice channel like `Hermes Voice`.
5. After the user enters the token locally, configure/verify Discord in Hermes Gateway without printing secrets, restart the gateway, then test text first and voice second.
6. See `references/discord-gateway-setup.md` for a concise user-facing setup handoff and secret-handling pattern.

## Approval / YOLO mode playbook

Use only when the user explicitly asks for persistent no-confirmation command execution.

1. Load `hermes-agent` first for the canonical approval-mode docs.
2. Set approval mode and verify the serialized YAML value:
   - `hermes config set approvals.mode off`
   - Inspect `~/.hermes/config.yaml` around `approvals:`.
3. If the config writer serializes the value as YAML boolean `false`, patch it to the literal string `off`:
   - Expected:
     ```yaml
     approvals:
       mode: off
     ```
   - Avoid leaving `mode: false` unless the current Hermes version explicitly documents boolean values.
4. Restart the gateway after config changes that affect Telegram/runtime behavior:
   - `hermes gateway restart`
   - `hermes gateway status`
5. Remind the user that `approvals.mode: off` bypasses command confirmation but does not grant root by itself; sudo still depends on Hermes sudo configuration and credentials.

## Voice interaction playbook

Use when the user wants voice-to-voice, hands-free, or "viva voce" interaction through Hermes.

1. Load `hermes-agent` first for canonical STT/TTS and `/voice` command docs.
2. Match the channel to the actual interaction style:
   - **Telegram**: asynchronous voice-message loop. User sends a voice note; Hermes transcribes it and can reply with TTS. Good mobile UX, but not continuous listening.
   - **CLI voice mode**: local PC microphone loop with `Ctrl+B`, silence detection, STT, and spoken replies. Good for hands-free work at the computer.
   - **Discord voice channel**: closest built-in option for live bidirectional conversation; Hermes can join a voice channel, listen, detect silence, transcribe, reason/use tools, and speak back.
   - **Phone wake-word**: requires a separate Android/app automation outside Telegram; Telegram Bot API cannot start/stop the user's microphone.
3. For Telegram voice replies, use chat commands when possible:
   - `/voice on` for voice-originated spoken replies.
   - `/voice tts` for spoken replies to all messages in that chat.
   - `/voice off` to return to text-only.
4. If selecting a TTS voice for an Italian user, Edge TTS has no-key Italian voices such as `it-IT-ElsaNeural`; restart/sync the gateway after config changes that affect runtime behavior.
5. See `references/voice-channel-options.md` for the decision matrix, Telegram limitation, and CLI/Discord alternatives.

## Pitfalls

- A valid Telegram bot token is not enough. Hermes Gateway may still deny all messages if no allowlist is configured.
- Do not default to `GATEWAY_ALLOW_ALL_USERS=true` or `approvals.mode: off` for convenience. Prefer a Telegram allowlist and normal approval prompts unless the user explicitly chooses open access / YOLO mode.
- When enabling persistent YOLO mode, verify the actual config file after `hermes config set`; some values may be coerced by YAML parsing/serialization and need a literal-string patch.
- Do not save or print bot tokens in summaries. Redact secrets and mention only whether they are present/valid.
- Some systemd keys are version-dependent. If `systemctl status` reports `Unknown key name`, patch/remove only those unsupported keys and run `systemctl --user daemon-reload`.
- `systemd-analyze --user verify` may fail in an agent/non-login environment even when the unit works; prefer actual `systemctl --user status` and journal verification when the user manager is running.

## References

- `references/telegram-systemd-setup.md` — concise worked pattern from a Hermes Gateway + Telegram setup where root PATH lacked `hermes`, user systemd needed `XDG_RUNTIME_DIR`, and Telegram required an allowlist/home channel.
- `references/persistent-yolo-mode.md` — focused notes on enabling permanent no-confirmation command execution for Hermes/Gateway and verifying the config serialization.
- `references/voice-channel-options.md` — voice-channel decision matrix: Telegram voice notes + TTS, CLI continuous voice mode, Discord voice channels, and why Telegram bots cannot do wake-word/continuous phone microphone capture.
- `references/discord-gateway-setup.md` — Discord server/bot setup handoff, safe secret-handling guidance, required bot intents/permissions, and recommended text/voice channel layout.
