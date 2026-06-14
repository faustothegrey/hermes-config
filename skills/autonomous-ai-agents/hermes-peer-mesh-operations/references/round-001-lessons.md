# Round 001 Lessons: Hermes Peer Experience Exchange

This reference condenses the first local Hermes peer exchange round. It is session-specific detail for the class-level `hermes-peer-mesh-operations` skill.

## Participants

- Local coordinator: default Hermes profile on Linux CLI.
- peer105: LAN Hermes API Server peer.
- peer128: LAN Hermes API Server peer.

## What happened

1. The coordinator discovered peer105 through the configured peer mesh.
2. peer128 was manually identified at `192.168.178.128:8642`.
3. peer128 responded to `/health` but initially rejected authenticated `/v1/capabilities` with `invalid_api_key`.
4. The local peer mesh config was extended with peer128 and a local `HERMES_PEER_128_KEY` variable.
5. peer128 still rejected auth until its API server/gateway was rebooted/restarted after `API_SERVER_KEY` configuration.
6. After restart, peer128 returned authenticated capabilities successfully.
7. The coordinator collected safe self-reports from peer105 and peer128, synthesized them, sent the synthesis back, collected feedback, and wrote a final synthesis.

## Durable lesson: liveness is not readiness

`/health` means the API server process is alive. It does not prove that authentication, model runtime, tools, or peer configuration are ready.

Readiness baseline:

- `/health` returns ok.
- Authenticated `/v1/capabilities` returns HTTP 200 and expected Hermes API Server features.
- Preferably, a tiny authenticated model/tool probe also succeeds.

## Auth pitfall and fix

Symptom:

- `GET /health` succeeds.
- `GET /v1/capabilities` with the expected bearer key returns 401 `invalid_api_key`.

Likely causes:

- Local peer key does not match the remote `API_SERVER_KEY`.
- Remote gateway/API server was not restarted after changing `API_SERVER_KEY`.
- Local MCP peer server has not re-read local `.env`/mesh config.

Fix pattern:

1. Confirm the remote peer has `API_SERVER_KEY` set to the intended value.
2. Restart the remote gateway/API server.
3. Confirm the local mesh entry points at the peer and uses the right `api_key_env`.
4. Confirm the local `.env` contains the peer-specific key variable.
5. Retry authenticated `/v1/capabilities`.

## Peer feedback highlights

Common high-signal skills/categories:

- `hermes-agent` for Hermes config/API/gateway/tools/cron/delegation/provider details.
- Systematic debugging workflows for reproduction, logs, root cause, fix.
- Test-driven development workflows for code edits.
- GitHub workflow skills only when the task is GitHub-shaped.
- Browser and Obsidian workflows are high-signal on peers that actually use those systems.

Restart/reset semantics from peers:

- `.env`, API, gateway/platform config changes: restart gateway/API server or start a new CLI process.
- Toolset changes: `/reset` or new session.
- Skills added/removed: reload skills or new session depending platform.
- Code changes: restart gateway/CLI.

Cron pattern from peers:

- Future cron runs have no current chat context; prompts must be fully self-contained.
- Watchdogs should often be script + `no_agent=True`; empty stdout means no alert.
- For recurring reports, emit only deltas or notable changes.
- Use `enabled_toolsets` to reduce context/tool bloat.

Delegation pattern from peers:

- Use delegation for bounded parallel subtasks, not durable background work.
- Pass all context explicitly.
- Ask subagents for verifiable handles.
- Verify side-effect claims before reporting success.

## Artifact pattern used

Reports were stored under a local exchange directory rather than memory:

```text
~/.hermes/peer-exchange/protocol.md
~/.hermes/peer-exchange/round-001-local.md
~/.hermes/peer-exchange/round-001-peer105.md
~/.hermes/peer-exchange/round-001-peer128.md
~/.hermes/peer-exchange/round-001-synthesis.md
~/.hermes/peer-exchange/round-001-peer-feedback.md
~/.hermes/peer-exchange/round-001-final-synthesis.md
```

## What not to persist as memory

Do not save per-round reports, one-off peer feedback, transient auth failures, or specific exchange artifacts in memory. Save only stable topology/preferences if they will remain useful. Procedures belong in this skill.
