# Discord voice auto-TTS routing lesson

## Situation

The user spoke through Discord voice and expected Hermes to answer aloud in the same voice channel. Hermes had already joined the voice channel and STT was working: gateway logs showed `VoiceReceiver started`, `Voice input from user ...`, and inbound Discord messages routed to the linked text channel.

The assistant incorrectly called `text_to_speech` manually and returned a `MEDIA:` audio file. That produced an attachment-style response instead of using the live Discord voice playback path.

## Correct routing model

For Discord voice input, `gateway/run.py::_handle_voice_channel_input()` builds a synthetic `MessageEvent` with `message_type=MessageType.VOICE` and feeds it through the normal adapter pipeline. When voice mode is enabled (`voice_only` or `all`) and global/per-chat auto-TTS allows it, gateway/platform code generates TTS and calls the Discord adapter's `play_tts()`.

The Discord adapter checks whether the text channel is linked to a connected voice guild. If so, `play_tts()` calls `play_in_voice_channel()` and plays the generated audio in the VC rather than posting an audio file.

## Practical implication for future agents

When replying to a live Discord voice utterance, just return the natural-language final answer. Avoid manual TTS tools and avoid `MEDIA:` tags unless the user explicitly asks for an audio file attachment. Manual TTS can be seen by the gateway as agent-produced media and can prevent the automatic voice-channel playback path from doing the right thing.

## Useful diagnostics

- `~/.hermes/logs/gateway.log` lines to look for:
  - `Discord voice auto-joined ... reason=text-trigger`
  - `VoiceReceiver started`
  - `Voice input from user ...`
  - `Playing TTS in voice channel`
- `~/.hermes/gateway_voice_mode.json` should include the Discord chat key with `voice_only` or `all`.
- `~/.hermes/config.yaml` should have `voice.auto_tts: true` if relying on the global default.
