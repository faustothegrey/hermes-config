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

**Pitfall — `cronjob action='run'` on LLM-driven jobs silently fails when agent slot is occupied**: If the parent session is active (you're in a conversation), the cron scheduler cannot spawn a new agent. The `action='run'` call returns `success: true` but the job never executes — `last_run_at` and `last_status` stay null. Fallback: read the job's prompt from `~/.hermes/cron/jobs.json`, extract the protocol, and execute it inline in the current session. Example: `python3 -c "import json; data=json.load(open('~/.hermes/cron/jobs.json')); [print(j['prompt']) for j in data['jobs'] if j['id']=='<job_id>']"`. This is particularly important for autonomous project loops — the user expects progress, not a silent no-op.

**Pitfall — `deliver: local` jobs never surface output in CLI**: When a cron job has `deliver: local`, its output is saved to disk only — it never reaches the chat. To verify these jobs, run their scripts directly with `terminal` or check the output files they produce.

## Kanban workers and orchestrators

Use kanban workflows for multi-agent/multi-profile work queues. Orchestrators decompose and route tasks; workers execute scoped tasks and update the board with comments, blockers, heartbeats, and completion evidence.

## Webhooks

Use webhook subscriptions for event-driven agent runs. Design routes, payload templating, validation, and delivery behavior explicitly. Test with a controlled POST before relying on external systems.

## MCP

Use native MCP configuration for stdio/HTTP MCP servers. Add, test, list, and configure tools through Hermes MCP commands; avoid hand-editing config unless necessary.

## Service supervision / containers

For s6-overlay or gateway service problems, inspect supervisor logs and process state first. Restart only the affected service when possible and preserve logs for root-cause analysis.

## Model/provider mismatch pitfall

The Hermes interactive model picker (`hermes model` without arguments) may show models from multiple providers. If the user selects a model whose slug belongs to a different provider than the active one, every API call fails permanently — not transient throttling, but a hard config error.

**Symptom signature** (provider `nous` + OpenRouter `:free` slug):
```
⚠️  API call failed: AuthenticationError [HTTP 401]
   🔌 Provider: nous  Model: nvidia/nemotron-3-ultra:free
   📝 Error: HTTP 401: Your API key is invalid, blocked or out of funds.
   ⚠️  Note: `nvidia/nemotron-3-ultra:free` looks like an OpenRouter slug (`:free` suffix).
        Nous Portal won't recognize that model name. Either switch to a
        Nous catalog model, or run `/model openrouter:nvidia/nemotron-3-ultra:free` to use OpenRouter.
```

**Diagnosis**: check `hermes model` to see the active provider and model. If the model slug has `:free` but the provider is `nous`, it's a mismatch. The 401 is permanent — no amount of retry or waiting will fix it.

**Fix (two options)**:
A. Switch provider to match the model: `hermes model openrouter:<model-slug>` (requires OpenRouter API key).
B. Keep the current provider and pick a model from its catalog: `hermes model` → select a Nous-native model.

**Do not** treat this as transient throttling with retry loops — that wastes resources and never resolves.

### Transient 401 from free-tier quota exhaustion (NOT the same as above)

Some free-tier models (especially via Nous Portal's free inference tier) return HTTP 401 when the tier's quota is exhausted, then recover silently when quota resets. This looks similar to the permanent mismatch but the symptom is **intermittent** — the peer responds sometimes and freezes other times with the same 401 message. When Hermes hits a 401 it aborts the agent loop; the gateway stays up (`/health` returns 200) but the agent is dead until restarted or until the user sends a new prompt.

**How to tell them apart**:
- **Permanent mismatch**: the model slug belongs to a different provider (e.g. `:free` OpenRouter slug with `nous` provider). 401 on EVERY call. No amount of waiting helps.
- **Free-tier quota exhaustion**: the model/provider pairing is correct. The peer *sometimes* responds normally (when quota is available) and sometimes 401s (when exhausted). The user will report "a volte funziona, a volte no."

**Do NOT** change the model/provider for the free-tier case — the pairing is correct, the quota is the bottleneck.

**Do NOT** implement retry loops that keep calling the LLM — they burn quota credits without fixing anything, and Hermes itself already retries before aborting.

**What to do instead**: deploy a multi-layer resilience architecture (see `references/constrained-peer-resilience.md`):
1. **Local watchdog** on the peer — systemd timer + bash script that checks `/health` and restarts the gateway if it's down. Cooldown prevents restart storms.
2. **Remote heartbeat** from the orchestrator — cron `no_agent=True` script that polls `/health` hourly and logs to JSONL. Silent data collection, no alerts unless the user asks for them.
3. **Autonomous project loop** (optional) — agent-driven cron on the orchestrator that wakes every 4-6 hours, reads an Obsidian project note, takes one atomic step, documents progress, and self-regulates. Use when the user wants to be completely out of the loop for a multi-phase project.
4. **SSH key setup** for direct orchestrator→peer access, because the peer API is unreliable when the agent is frozen.

### Model 404: Nous removed the model from their inference API (NOT the same as 401)

When a provider removes a model from their catalog, every API call returns HTTP 404 "Model not found." This looks like a configuration error or a misspelled model ID, but the real cause is the provider retired the model. The previously-working model simply ceases to exist.

**Symptom signature**:
```
Error code: 404 - {'status': 404, 'message': "Model 'nvidia/nemotron-3-ultra:free' not found. 
The requested model does not exist in our configuration or OpenRouter catalog."}
```

**Diagnosis**: Check if the same model/provider pair ever worked before. Search the web for the provider's current model catalog. The Nous inference API currently serves `Hermes-4.3-36B`, `Hermes-4-70B`, `Hermes-4-405B`, and `deepseek/deepseek-chat` (among others). Free-tier models like `nvidia/nemotron-3-ultra:free` may be retired without notice.

**Fix**: Switch to a model the provider currently serves. For Nous provider, `deepseek/deepseek-chat` is a reliable fallback that works without an additional API key. Verify with a lightweight call_peer test prompt before declaring it fixed.

**Pitfall — `hermes config set models.default` writes to the wrong key**: The command `hermes config set models.default <model>` writes to YAML key `models:` (plural), but the gateway and API server read from `model:` (singular). The result is a successful config write that the gateway silently ignores — the old model keeps being used. Fix: use `sed` to directly edit the `model:` section, or run `hermes config set model.default <model>` (singular).

## Verification

Every operational change should end with a real status check: `hermes status`, `hermes doctor`, gateway logs, cron list/status, webhook test, kanban board state, MCP test, or service health output.
