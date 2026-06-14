---
name: hermes-operations
description: "Operate Hermes runtime systems: agent config, gateway/voice, cron/background jobs, kanban workers, webhooks, skills, MCP, and service supervision."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, gateway, discord, voice, cron, kanban, webhooks, mcp, skills]
---

# Hermes Operations

Use this class-level skill when configuring, extending, operating, or troubleshooting Hermes runtime systems: agent config/providers/tools, gateway and voice mode, background jobs, kanban workers, webhooks, MCP, skill authoring, and service supervision.

## Source of truth

For current commands and behavior, consult the Hermes docs and the main `hermes-agent` skill. This umbrella organizes operational workflows and points to the right subsystem.

## Agent configuration, updates, skills, and memory hygiene

Use `hermes config`, `hermes model`, `hermes tools`, and `hermes skills` for user-facing configuration. For skill authoring, follow SKILL.md structure: frontmatter, clear triggers, numbered workflow, pitfalls, verification, and support files under `references/`, `templates/`, `scripts/`, or `assets/`.

When the user has an external knowledge base such as Obsidian, keep Hermes permanent memory compact: store only stable preferences, essential paths, and pointers to notes. Move detailed service topology, command recipes, troubleshooting history, peer status, backup mechanics, and long procedures into class-level Obsidian notes, then link them from an index such as `Hermes/Overview.md`. See `references/operational-memory-obsidian.md`.

### Updating Hermes with local modifications

When the user asks to update Hermes and the checkout has local modifications:

1. Inspect current status and record the branch/modified paths.
2. Stash explicitly before update, preferably with a timestamped message: `git stash push -u -m "pre-update-$(date +%Y%m%d-%H%M%S)"`.
3. Run the update (`hermes update --yes` when the user has already approved the update path).
4. Re-apply with `git stash apply stash@{0}` rather than `git stash pop` so the stash remains preserved if conflicts occur.
5. If conflicts occur, stop immediately unless the user already authorized conflict resolution. Report unmerged files, applied/staged files, current `HEAD`/`origin/main`, and confirm the stash is still present.
6. Verify with `hermes --version` and `git status --short --branch` before final response.

## Gateway, voice, and local audio I/O

Use gateway workflows for Telegram/Discord/Slack/etc. For Discord voice:

- Voice inbound replies should usually be normal final text; the gateway handles auto-TTS routing.
- Do not manually call TTS unless the user explicitly asks for an audio attachment.
- Debug STT, TTS, auto-join, routing, and permissions separately.

For messaging-platform voice mode changes, verify the actual per-chat gateway state instead of only changing global config:

1. Inspect `~/.hermes/gateway_voice_mode.json`; keys are platform-prefixed, e.g. `telegram:<chat_id>` or `discord:<channel_id>`, and values are `off`, `voice_only`, or `all`.
2. Remember that `voice.auto_tts` in `config.yaml` is only the global default. A per-chat `off` entry suppresses auto-TTS even if the global default is true.
3. `/voice off` writes the per-chat hard override and syncs adapter `_auto_tts_disabled_chats`; `/voice on` or `/voice tts` writes an explicit opt-in.
4. For Discord live voice channels, separately inspect `discord.voice_auto_join.enabled` and any running gateway/voice services. Telegram voice notes are not Discord voice-channel auto-join.
5. Verification should include the persisted JSON state plus live service/process status when the user asks to disable a channel or voice feature.

For local wake-word daemons that should summon Hermes into Discord voice, use a local atomic trigger file watched by the Gateway after Discord connects; see `references/discord-local-wakeword-bridge.md` for the pattern, stale-trigger guard, and verification checklist.

For local speaker/microphone checks from a Hermes CLI session:

1. Inspect audio routing before assuming TTS is broken: `pactl list short sinks`, `pactl get-default-sink`, `pactl get-sink-volume @DEFAULT_SINK@`, and `pactl get-sink-mute @DEFAULT_SINK@`.
2. If the user hears nothing, check for the simple failure mode first: default sink muted or volume at 0%. Fix with `pactl set-sink-mute @DEFAULT_SINK@ 0` and a moderate `pactl set-sink-volume @DEFAULT_SINK@ 50-60%`, then verify with `pactl get-sink-volume` and `pactl get-sink-mute`.
3. Prefer Hermes `text_to_speech` output for natural voice tests; system speech like `spd-say` can sound mechanical. Play the generated audio with `mpv --no-video`, or fallback to `ffplay`, or convert MP3 to WAV with `ffmpeg` and play via `paplay`.
4. For external microphone confirmation, inspect `pactl list short sources`, `pactl get-default-source`, `pactl list sources`, `arecord -l`, and USB identity (`lsusb` when available). Report whether the external USB source is detected and whether it is the default source.
5. Verification should include an actual audible test or capture/routing check, not just listing devices.

## Background operations and cron

Use cron jobs for durable scheduled tasks. Use background terminal processes with `notify_on_complete=true` for bounded long commands. Keep prompts self-contained because scheduled jobs run in fresh sessions.

## Kanban workers and orchestrators

Use kanban workflows for multi-agent/multi-profile work queues. Orchestrators decompose and route tasks; workers execute scoped tasks and update the board with comments, blockers, heartbeats, and completion evidence.

## Webhooks

Use webhook subscriptions for event-driven agent runs. Design routes, payload templating, validation, and delivery behavior explicitly. Test with a controlled POST before relying on external systems.

## MCP

Use native MCP configuration for stdio/HTTP MCP servers. Add, test, list, and configure tools through Hermes MCP commands; avoid hand-editing config unless necessary.

## Service supervision / containers

For s6-overlay or gateway service problems, inspect supervisor logs and process state first. Restart only the affected service when possible and preserve logs for root-cause analysis.

## Verification

Every operational change should end with a real status check: `hermes status`, `hermes doctor`, gateway logs, cron list/status, webhook test, kanban board state, MCP test, or service health output.
