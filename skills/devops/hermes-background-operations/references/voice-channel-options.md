# Hermes voice interaction channels

Use these notes when a user asks for voice-first or hands-free operation through Hermes Gateway.

## Telegram: voice-message loop, not continuous listening

Telegram is good for asynchronous voice-message interaction:

- User sends a Telegram voice note.
- Hermes Gateway downloads/transcribes it via the configured STT provider (`stt.enabled: true`, provider `local`, `groq`, `openai`, or `mistral`).
- The agent receives the transcript as text and can use tools normally.
- `/voice on` or `/voice tts` enables spoken TTS responses; Telegram delivery should use a voice-compatible audio format (OGG/Opus works well, and Hermes TTS media delivery handles this path).

Important limitation: Telegram Bot API bots cannot activate the user's microphone, listen for a wake word, record in the background, or stop the user's recording on silence. Telegram bots receive voice files only after the Telegram client/user has recorded and sent them. Do not promise a pure hands-free wake-word experience inside Telegram alone.

Useful commands/config:

```bash
# Per-chat voice modes from the messaging chat
/voice on       # spoken replies for voice-originated interaction
/voice tts      # spoken replies for all messages in that chat
/voice off      # text-only replies
/voice status

# TTS voice choice example
hermes config set tts.provider edge
hermes config set tts.edge.voice it-IT-ElsaNeural

# STT is normally already enabled
hermes config set stt.enabled true
```

Persisted per-chat voice mode lives in `~/.hermes/gateway_voice_mode.json` with platform-prefixed keys such as `telegram:<chat_id>` and values `voice_only`, `all`, or `off`. Prefer the `/voice ...` command from the chat when possible; direct edits are useful only for recovery/admin work and require gateway sync/restart.

## CLI voice mode: local continuous loop

The Hermes CLI supports a more continuous local microphone loop:

- `/voice on` enables voice mode.
- Press `Ctrl+B` to start recording.
- Hermes detects silence, stops, transcribes, sends to the agent, speaks the reply if TTS is on, and can continue the loop.

This is good for hands-free work at the PC, but it is not a Telegram mobile microphone integration.

## Discord voice channels: closest to true live conversation

For real bidirectional spoken conversation, prefer Discord voice channels when acceptable:

- Hermes can join a Discord voice channel via `/voice join` or `/voice channel`.
- The Discord adapter can listen to users speaking, buffer utterances, detect silence, run STT, pass text to the agent, then play TTS back into the voice channel.
- This is the closest built-in Hermes path to: user speaks → silence ends utterance → Hermes interprets/tools → Hermes speaks back.

Point users asking for "viva voce", wake-word-like, or continuous conversation toward Discord voice or CLI voice mode, not Telegram-only bots.

## Android/wake-word alternative

If the user specifically wants phone-level wake word activation (e.g. "Ok Hermes"), explain that it needs a separate Android app/automation outside Telegram:

1. Wake-word or push-to-talk capture on the phone.
2. Voice activity detection to stop on silence.
3. Send the audio/transcript to Hermes through the API server, webhook, or a messaging platform.
4. Deliver the spoken response back through Telegram/Discord/another channel.

This is a custom integration, not a Telegram Bot API feature.
