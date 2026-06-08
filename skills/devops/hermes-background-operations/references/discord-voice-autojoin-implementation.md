# Discord voice auto-join implementation notes

Use these notes when a user wants Hermes Gateway to behave like an always-on Discord voice room: join a configured voice channel at startup, bind voice turns to a text channel, listen continuously, speak replies, and reconnect after drops/restarts.

## When this applies

- User explicitly asks for hands-free/always-on Discord voice, not only manual `/voice join`.
- The protected `hermes-agent` docs do not yet expose a built-in startup auto-join feature for the installed version, or the installed code/config must be verified.
- The target machine is trusted/dedicated enough for a persistent gateway listener.

## Resource and policy default

Always-on voice should be opt-in, not the default. Explain the tradeoff before enabling or keeping it enabled:

- the Discord voice connection itself is usually a small but continuous websocket/UDP/network cost;
- continuous listening/audio receive and STT are the real cost risk, especially with local Whisper CPU/GPU work or metered cloud STT;
- TTS and LLM calls generally cost only when Hermes actually replies, but false triggers/noisy rooms can still create work;
- some users prefer the bot not to appear as permanently listening in a voice room.

Prefer one of these safer defaults unless the user explicitly wants always-on hands-free operation:

1. Manual activation only (`/voice join` / `/voice on`).
2. Keep `discord.voice_auto_join.enabled: false` while preserving channel IDs for quick future re-enable.
3. Text-triggered join (`text_trigger: true`, e.g. trigger word `voce`) with startup auto-join disabled.
4. Text-triggered join plus a short initial idle guard (`text_trigger_initial_activity_timeout`, e.g. 30s) so the bot leaves if nobody speaks right after the trigger.
5. Auto-join with normal idle timeout, not `disable_timeout: true`.
6. A bounded idle timeout such as 30–60 minutes if the implementation supports it.

To disable auto-join after a local patch/config exists, use the Hermes config CLI instead of direct file-tool writes to protected config:

```bash
hermes config set discord.voice_auto_join.enabled false
hermes config set discord.voice_auto_join.reconnect false
hermes config set discord.voice_auto_join.disable_timeout false
hermes gateway restart
```

Then verify `hermes-gateway.service` is active and re-read the config around `discord.voice_auto_join`.

## Feature shape

Expected config shape:

```yaml
discord:
  voice_auto_join:
    enabled: true
    guild_id: "<discord guild/server id>"
    text_channel_id: "<paired text channel id>"
    voice_channel_id: "<voice channel id>"
    mode: all        # listen + speak where Hermes supports it
    reconnect: true
    disable_timeout: true
    text_trigger: true
    trigger_words: voce
    text_trigger_initial_activity_timeout: 30  # leave if no audio after a text-trigger join
```

Two related but distinct modes can share the same config block:

- Startup/reconnect auto-join: `enabled: true` and optionally `reconnect: true`.
- Manual text trigger: `enabled: false`, `text_trigger: true`, and a short trigger word such as `voce` lets the user summon the bot without permanent startup listening.

The text-trigger mode should support an initial idle auto-leave window. After a successful `reason="text-trigger"` join, record `time.monotonic()`, wait `text_trigger_initial_activity_timeout`, inspect the Discord voice receiver's persistent last-audio timestamp (for example `_voice_receivers[guild_id]._last_activity_time`) plus current packet timestamps, or fall back to `speaking_count`, and leave/clean up voice mode if no audio arrived after the join. Do not rely only on `_last_packet_time`: the receiver clears those entries when an utterance completes, so a user can speak successfully and still be treated as idle 30s later. Do not count mere channel presence as activity.

The implementation should:

1. Load `discord.voice_auto_join` during gateway startup after the Discord adapter/client is available.
2. Resolve guild, text channel, and voice channel by ID; fail visibly in logs if any ID is wrong.
3. Start/join a voice session bound to the configured text channel so transcripts/tool-use context land in the right conversation.
4. Set the voice mode persistently for the paired text channel/session (`all` for STT + TTS when requested).
5. For text-triggered joins, schedule at most one initial idle check per guild. Cancel/replace any previous pending check when a new trigger joins the same guild.
6. Disable or bypass idle disconnect for the configured auto-join voice channel when `disable_timeout` is true.
7. Start a reconnect loop/watchdog when `reconnect` is true; use a modest interval such as 30s and avoid duplicate concurrent joins.
8. Log a clear success line including guild/channel names and mode, without secrets.

## Verification checklist

Before telling the user it is done:

- Run static/syntax checks on modified Hermes files.
- Use the Hermes repo's own virtualenv/interpreter for tests when present (for this install shape, discover it via the `hermes` wrapper or use `~/.hermes/hermes-agent/venv/bin/python`), not the ambient shell Python/Conda interpreter.
- Run the relevant Discord voice/gateway tests if present; at minimum run the voice command tests around join/leave/mode behavior, including text-trigger initial idle leave when touched.
- Run Hermes' Discord voice readiness/doctor check if available.
- Restart the gateway service, not only the foreground process.
- Verify service status is active/running.
- Verify logs contain a success line like `Discord voice auto-joined ... mode=all reason=startup`.
- Verify the Discord API/state sees the bot in the target voice channel, not merely online.
- Verify the paired text channel has voice mode persisted as expected.

## Rollback pattern

For local Hermes code patches, create rollback handles before editing:

- a git branch named for the feature/date;
- a pre-change tarball or copy of the Hermes repo files being modified;
- a pre-change copy of `~/.hermes/config.yaml`;
- a local commit after verification.

Report the exact branch, commit, backup paths, and minimal rollback commands.

## Pitfalls

- Do not imply startup auto-join exists unless config/code/logs prove it. Manual `/voice join` remains the safe default path.
- Do not bind voice to the voice channel alone; Hermes still needs the paired text channel for conversation context, transcripts, command routing, and delivery.
- Do not leave the default idle timeout active for an always-on room unless the user wants auto-disconnect.
- Avoid reconnect loops that stack multiple voice clients. Check current connection/channel before joining again.
- For text-trigger initial idle leave, compare audio packet time against the post-trigger join timestamp. A speaking user before the bot joined, or a user merely sitting silently in the voice channel, should not prevent the initial auto-leave.
- Keep Discord bot tokens and other secrets out of logs and summaries; channel/guild IDs are okay to report when needed.
- A local patch may conflict with future `hermes update`; always leave a rollback/commit trail.
