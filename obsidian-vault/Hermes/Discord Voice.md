# Discord Voice

## Current local Hermes patch/config context

Hermes default profile has/had a local patch on branch:

```text
fausto/discord-voice-autojoin-20260530-093524
```

Purpose of the patch:

- configurable Discord voice auto-join;
- manual text trigger via `discord.voice_auto_join`;
- text-trigger initial idle auto-leave.

Current intended config notes:

- startup auto-join disabled:
  - `enabled=false`
  - `reconnect=false`
  - `disable_timeout=false`
- text trigger enabled:
  - `text_trigger=true`
  - trigger word: `voce`
- text channel:
  - `#hermes-chat`
  - id `1508809523459133581`
- voice channel:
  - `Hermes Voice`
  - id `1508809595949420608`
- mode: `all`
- after a text-trigger join, leave again after ~30s if no voice audio activity is detected.

## Voice-channel response behavior

On this Hermes Discord setup, voice-channel replies are handled by gateway auto-TTS when the inbound event is `MessageType.VOICE` and voice mode is enabled.

Important: the assistant should reply with plain text, not call `text_to_speech` and not include `MEDIA:...`, because agent TTS/media tags suppress voice-channel playback.

## Local wake-word bridge

`quasar-voice-detection.service` runs `/home/fausto/quasar-voice-detection/hey_hermes.py` and listens for “Hey Quasar”. On detection it writes `~/.hermes/discord_voice_wake_trigger.json`.

Hermes Gateway has a local patch that watches that trigger file after Discord connects and calls the configured Discord voice auto-join path with `reason="wake-word"`, using:

- text channel: `#hermes-chat` / `1508809523459133581`
- voice channel: `Hermes Voice` / `1508809595949420608`
- mode: `all`

The watcher ignores stale trigger files on gateway startup, so old wake events do not auto-join after restarts. Manual verification on 2026-06-13 showed: detector dispatch writes the trigger, gateway logs `Discord voice wake trigger received: hey quasar`, and join result is `True`.

## User preference

Fausto expects Discord voice-channel conversations to be answered aloud in the voice channel, preferably with an Italian-sounding TTS voice/accent rather than a foreign/Portuguese-sounding accent.
