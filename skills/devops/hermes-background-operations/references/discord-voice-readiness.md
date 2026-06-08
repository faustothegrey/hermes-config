# Discord voice readiness for Hermes Gateway

Use these notes when the user wants live, hands-free voice with Hermes through Discord.

## What "ready" means

Before telling the user Discord voice is ready, verify these categories rather than only checking that the Discord bot is online:

- Gateway is running and the Discord adapter is connected.
- The bot can see the target Discord guild/server.
- There is a text channel for transcript/context, commonly `#hermes-chat`.
- There is a voice channel for audio, commonly `Hermes Voice`.
- The bot has channel permissions: View Channel, Connect, Speak, Send Messages, Read Message History.
- Discord voice Python dependencies are importable/available: discord.py voice support, PyNaCl, davey/E2EE support when Hermes expects it, and Opus loading.
- `ffmpeg` is available for audio playback/encoding paths.
- STT is enabled and backed by a working provider. A local `faster-whisper` base model is a good no-key default.
- TTS is enabled and backed by a working provider. For Italian users, Edge TTS with `it-IT-ElsaNeural` is a good no-key default.

## User-facing activation

If Hermes is configured and ready but not auto-joined, the normal activation flow is:

1. User joins the Discord voice channel, e.g. `Hermes Voice`.
2. User sends `/voice join` or `/voice channel` in the paired text channel, e.g. `#hermes-chat`.
3. Hermes joins the user's voice channel, listens, transcribes utterances into the text channel/session context, reasons/uses tools, then speaks the reply through TTS.
4. User can leave with `/voice leave`.

Phrase this as a manual activation path, not as always-on behavior.

## Important limitation: no implicit startup auto-join

Do not imply that Hermes will automatically rejoin a Discord voice channel after gateway restart unless the current code/config has an explicit auto-join feature enabled.

If the user wants an always-on room, the feature/config shape is:

```yaml
discord:
  voice_auto_join:
    enabled: true
    guild_id: "..."
    voice_channel_id: "..."
    text_channel_id: "..."
    mode: all
    reconnect: true
    disable_timeout: true
```

Implementation needs to:

- read this config at gateway startup;
- connect the bot to the configured voice channel;
- bind the voice session to the configured text channel for context/transcripts;
- enable listening and spoken TTS replies;
- avoid or tune idle auto-disconnect for always-on use;
- reconnect after gateway/system restarts;
- verify success from gateway logs and Discord voice state/API, not just from command output.

Treat this as a Hermes feature/code change unless verified otherwise by current docs/config. See `discord-voice-autojoin-implementation.md` for the concrete implementation/verification checklist.

## Reporting guidance

For a user who wants practical next steps, give the shortest working path first:

- "Join `Hermes Voice`, then type `/voice join` in `#hermes-chat`."

Then state the limitation and the optional permanent auto-join implementation. Avoid burying the working command under a long explanation.
