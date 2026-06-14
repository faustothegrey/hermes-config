# Local voice wake notification without Discord auto-join

Use when the user wants a local wake-word detector to notify Hermes or a messaging channel, but explicitly does **not** want Hermes to join Discord voice yet.

## Pattern

1. Treat wake-word detection as a local event source, not as permission to start a voice session.
2. Write a neutral trigger file such as:

```text
~/.hermes/local_voice_wake_trigger.json
```

Avoid writing the gateway's Discord voice auto-join trigger path if the user only wants notification:

```text
~/.hermes/discord_voice_wake_trigger.json
```

3. Send a lightweight notification to the user's chosen channel. For this user's current local setup, the requested message text is:

```text
Local Voice Wakeup Detected
```

4. Keep the handler deterministic and cheap: no LLM turn, no Discord join, no STT beyond the wake recognizer unless explicitly requested later.
5. Restart only the affected service(s), then verify with logs and a real notification test.

## Implementation sketch

For a Python wake-word daemon:

```python
HERMES_WAKE_TRIGGER_PATH = Path.home() / ".hermes" / "local_voice_wake_trigger.json"
TELEGRAM_ENV_PATH = Path.home() / ".hermes" / ".env"
TELEGRAM_WAKE_TEXT = "Local Voice Wakeup Detected"
```

Read only the needed Telegram fields from `.env` without printing secrets:

```python
TELEGRAM_BOT_TOKEN
TELEGRAM_HOME_CHANNEL
TELEGRAM_HOME_CHANNEL_THREAD_ID  # optional
```

Send directly to Telegram's `sendMessage` endpoint via stdlib `urllib` or via the Hermes `send_message` tool when running inside an agent turn. For a daemon, direct Telegram API is often simpler and avoids starting an agent turn.

## Verification

After code changes:

```bash
python3 -m py_compile /path/to/wake_daemon.py
systemctl --user restart quasar-voice-detection.service
systemctl --user restart hermes-gateway.service  # only if it may still be joined/holding old watcher state
journalctl --user -u quasar-voice-detection.service --since '2 minutes ago' --no-pager
```

Then trigger the wake phrase and verify:

- daemon log has `WAKE WORD DETECTED`;
- neutral trigger file mtime changed;
- Telegram message arrived;
- gateway logs do **not** show `Discord voice auto-joined` / `wake trigger join result` for the new wake.

## Pitfalls

- Do not assume `voice_auto_join.enabled: false` prevents all wake-trigger joins: existing gateway code may call auto-join with `require_enabled=False` when the specific Discord trigger file changes. Avoid touching that trigger file.
- Restarting the gateway can be useful after disabling auto-join behavior because it drops any existing Discord voice connection from previous wake tests.
- If the user later asks to define behavior after wake, add a new explicit action at that time; do not infer Discord voice join as the default.
