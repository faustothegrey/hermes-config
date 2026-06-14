# Discord local wake-word bridge

Use this reference when a local always-on microphone daemon should summon Hermes into Discord voice without requiring a Discord text trigger.

## Pattern

1. Keep Discord channel routing in `discord.voice_auto_join`:
   - `guild_id`
   - `text_channel_id`
   - `voice_channel_id`
   - `mode: all`
   - startup auto-join may remain disabled (`enabled: false`).
2. The local wake-word service writes an atomic trigger file under Hermes home, e.g. `~/.hermes/discord_voice_wake_trigger.json`, with a small JSON payload:
   - `phrase`
   - `source`
   - `timestamp`
   - optional `pid`
3. Hermes Gateway, after the Discord adapter connects, starts a lightweight background watcher for that trigger file.
4. On a fresh mtime, the watcher calls the same Discord voice auto-join helper used by text-trigger/startup auto-join, but with `require_enabled=False` and `reason="wake-word"`.
5. The join helper must bind the voice session to the configured text channel and enable the configured voice mode, so transcripts and spoken replies route through the normal Discord voice pipeline.

## Implementation notes

- Use atomic writes for the trigger (`write temp file` + `os.replace`) so the gateway never reads partial JSON.
- Add a short cooldown in the wake-word daemon to prevent repeated sliding-window detections from spamming joins.
- Start the watcher only after Discord is connected and `voice_auto_join` has complete channel IDs.
- Do not require `voice_auto_join.enabled: true` for wake-word-triggered joins; that flag controls startup auto-join, not explicit local wake events.
- Ignore stale trigger files on gateway startup by initializing the watcher's `last_mtime` from the existing trigger file before entering the polling loop.
- If the watcher is scheduled before `GatewayRunner._running` is set true, its loop should not be `while self._running and ...`; otherwise it exits immediately. Prefer `while not shutdown_event.is_set()` for tasks scheduled during startup.
- Log both watcher startup and wake handling: `watching <path>`, `wake trigger received`, `auto-joined ... reason=wake-word`, and `join result`.

## Verification checklist

- `python -m py_compile` modified gateway and wake-word scripts.
- Run the relevant Discord voice/gateway test if the text-trigger/auto-join helper was touched.
- Restart Hermes Gateway and confirm logs show the watcher is watching the trigger file.
- Restart the wake-word service and confirm it reaches the listening state.
- Manually invoke the wake-word daemon's dispatch path or write the trigger file and verify gateway logs show `wake trigger received` and `join result: True`.
- Confirm stale trigger files are ignored after a gateway restart by checking there is no wake handling until a new atomic write occurs.
