# Hermes Peer Experience Exchange

Last updated: 2026-06-14

## Purpose

A safe Hermes-to-Hermes operational experience exchange across LAN/API peers. The goal is to share reusable lessons about system constraints, challenges, achieved workflows, failures, and recommendations without sharing secrets, raw env dumps, credentials, private user content, or sensitive personal data.

## Current mesh

Local coordinator: default Hermes profile on fausto-N56VV.

Configured peer mesh file:

```text
/home/fausto/.hermes/peer-mesh.yaml
```

Current reachable peers:

- `peer105`: `http://192.168.178.105:8642`
- `peer128`: `http://192.168.178.128:8642`

Peer API keys are stored in `/home/fausto/.hermes/.env` as peer-specific environment variables. Do not copy key values into notes or reports.

## Round 001 status

Round 001 completed on 2026-06-14.

Artifacts:

```text
/home/fausto/.hermes/peer-exchange/protocol.md
/home/fausto/.hermes/peer-exchange/round-001-local.md
/home/fausto/.hermes/peer-exchange/round-001-peer105.md
/home/fausto/.hermes/peer-exchange/round-001-peer128.md
/home/fausto/.hermes/peer-exchange/round-001-synthesis.md
/home/fausto/.hermes/peer-exchange/round-001-peer-feedback.md
/home/fausto/.hermes/peer-exchange/round-001-final-synthesis.md
```

## Main lessons from round 001

- `/health` is liveness only, not readiness.
- Peer readiness should include authenticated `/v1/capabilities`.
- Ideally also run a tiny authenticated model/tool probe before trusting a peer for work.
- After changing `API_SERVER_KEY`, restart the gateway/API server.
- Keep memory declarative and durable only.
- Put reusable procedures in skills.
- Keep round reports and raw peer feedback in files, not memory.
- Use tools for current/system facts and verification.
- Treat peer and subagent summaries as self-reports until verified.
- Exchange operational failure patterns and heuristics, not private user data or secrets.

## Readiness checklist for peers

1. Add peer to `/home/fausto/.hermes/peer-mesh.yaml`.
2. Store its API key in `/home/fausto/.hermes/.env` as a peer-specific env var.
3. Verify `/health`.
4. Verify authenticated `/v1/capabilities`.
5. Ideally run a tiny authenticated model/tool probe.
6. Restart peer gateway/API server after changing `API_SERVER_KEY`.

## Round 002 plan

Scheduled for 2026-06-21 around 20:09 local time.

Round 002 should:

1. Load the Hermes Agent skill.
2. Review `/home/fausto/.hermes/peer-exchange/round-001-final-synthesis.md`.
3. Check peer health and authenticated capabilities for peer105 and peer128.
4. Ask peers for deltas since round 001, especially:
   - new gateway/API/model/provider failures and fixes
   - robust cron/delegation prompt patterns
   - high signal-to-context skills
   - corrections to round 001
5. Save round 002 artifacts under `/home/fausto/.hermes/peer-exchange/`.
6. Produce a synthesis and send compact review digest back to peers.
7. Remind the user to decide whether to create the reusable skill `hermes-peer-experience-exchange`.

## Skill creation reminder

The next round should explicitly remind the user that the workflow is ready to become a reusable skill named something like:

```text
hermes-peer-experience-exchange
```

The skill should include:

- peer discovery/readiness checklist
- self-report prompt
- privacy/safety rules
- file layout
- synthesis workflow
- peer feedback loop
- cron scheduling guidance
