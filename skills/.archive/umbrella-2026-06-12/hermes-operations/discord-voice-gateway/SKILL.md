---
name: discord-voice-gateway
description: "Operate and troubleshoot Hermes Discord voice-channel mode: voice auto-join, STT input, auto-TTS replies, and routing pitfalls."
version: 1.0.0
created_by: agent
tags: [hermes, discord, gateway, voice, tts, stt]
---

# Discord Voice Gateway

Use this skill when the user is working with Hermes over Discord voice channels: configuring voice auto-join, diagnosing why Hermes hears but does not speak, checking STT/TTS routing, or responding to a voice-channel conversation.

## Core rule for voice-channel conversations

When the inbound message is from Discord voice, **reply with normal final text** unless the user explicitly asks for an audio file attachment. Do **not** call `text_to_speech` manually and do **not** include a `MEDIA:` audio tag in the final answer.

Why: Hermes gateway already auto-generates TTS for `MessageType.VOICE` events when voice mode is enabled. On Discord, the adapter's `play_tts()`/`play_in_voice_channel()` path plays that audio directly in the connected voice channel. If the assistant manually creates a TTS media file, it can bypass or suppress the voice-channel playback path and deliver a file/text response instead of speaking in the VC.

## Quick checks

1. Confirm Hermes joined the target voice channel in `~/.hermes/logs/gateway.log`:
   - `Discord voice text trigger '...' accepted ...`
   - `Discord voice auto-joined ... reason=text-trigger`
   - `VoiceReceiver started`
   - `Voice input from user ...`
2. Confirm the chat has voice replies enabled:
   - `~/.hermes/gateway_voice_mode.json` should include the Discord text channel with mode `voice_only` or `all`.
   - `/voice status` in Discord should show voice replies enabled.
3. Confirm config enables the default auto-TTS path if relying on global mode:
   - `voice.auto_tts: true` in `~/.hermes/config.yaml`.
4. Confirm `discord.voice_auto_join` maps the text channel to the voice channel and has the expected trigger behavior.
5. For Italian voice input, verify STT is not effectively defaulting to English:
   - `hermes config set stt.enabled true`
   - `hermes config set stt.provider local`
   - `hermes config set stt.local.language it`
   - If using a hosted STT provider later, set the equivalent Italian language option or use provider autodetect intentionally.
6. When a voice turn seems delayed or lost, compare timestamp order in `gateway.log`: user join/leave events, `Voice input from user`, `response ready`, `Playing TTS in voice channel`, and final `Sending response`. If `Voice input` appears only after the user left, troubleshoot capture/STT latency rather than assuming the agent ignored the speech.

## User-facing response pattern

If the user says they expected a spoken reply in the Discord voice channel:

1. Acknowledge the mismatch briefly.
2. Explain that Discord voice input is being received if logs/STT show transcripts.
3. State the fix/behavior: future voice-channel replies should be plain assistant text so gateway auto-TTS speaks them in the VC.
4. Then respond normally, without `MEDIA:` audio.

## Common pitfall

**Pitfall:** Calling `text_to_speech` from the assistant because the user wants a voice reply.

**Correction:** In Discord voice sessions, leave TTS generation to the gateway. Manual TTS is appropriate for platforms or contexts where the user requested an audio attachment, but it is the wrong path for live Discord voice playback.

## Reference notes

See `references/discord-voice-autotts-routing.md` for the session-specific routing lesson and code-path landmarks.