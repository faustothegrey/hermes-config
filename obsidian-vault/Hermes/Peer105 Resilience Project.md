# Peer105 Resilience Project

## Goal
Rendere peer105 (192.168.178.105) autonomo e resiliente ai 401 da quota free-tier
esaurita, senza bisogno di intervento umano. Progetto a tappe, esecuzione lenta.

## Architecture (target)
```
peer105                                     orchestrator (N56VV)
┌──────────────────────────┐              ┌─────────────────────────────┐
│ watchdog.sh (ogni 10min) │              │ hermes cron (ogni 4h)       │
│  curl /health            │◄─────────────│  questo progetto            │
│  restart se giù          │              │  valuta, agisce, documenta  │
│                          │              │                             │
│ v2: freeze detection     │              │ heartbeat.py (ogni ora)     │
│ v3: llm retry wrapper    │              │  log JSONL sanitario        │
│ v4: yt-summarize cron    │              │                             │
└──────────────────────────┘              └─────────────────────────────┘
```

## System info
- Host: 192.168.178.105, localhost.localdomain
- OS: Fedora 30 aarch64, kernel 5.0.9
- RAM: very limited (swaps at idle)
- Hermes: v0.15.1, systemd user service (root), PID varies
- Model: nvidia/nemotron-3-ultra:free via nous portal
- Problem: 401 when free quota exhausted → agent loop freezes
- SSH: root@192.168.178.105 (key auth from fausto@N56VV)

## Project Phases

### ✅ Phase 0 — Foundation (2026-06-18)
- [x] SSH access established
- [x] Watchdog v1 deployed (health check + restart)
- [x] Heartbeat monitoring from orchestrator
- [x] Project Obsidian note created
- [x] Autonomous project loop created

### 🔲 Phase 1 — Remote Observability
Improve ability to understand peer105 state without touching it:
- [ ] System resource monitoring (RAM, CPU, swap)
- [ ] Hermes log monitoring (detect freeze patterns)
- [ ] Dashboard-like status snapshot
- [ ] Historical data for pattern recognition

### 🔲 Phase 2 — Freeze Detection (Watchdog v2)
- [ ] Reliably detect "agent frozen, gateway alive" state
- [ ] Differentiate from "quota exhausted, waiting"
- [ ] Auto-restart only when appropriate

### 🔲 Phase 3 — LLM Retry Wrapper
- [ ] Python script wrapping LLM calls with backoff
- [ ] Handle 401 gracefully: wait, retry, give up cleanly
- [ ] Never infinite loop

### 🔲 Phase 4 — YouTube Summarization
- [ ] yt-dlp transcript download (local only)
- [ ] Batch processing with retry wrapper
- [ ] One video at a time, no rush

## Operation Log

### 2026-06-18
- 21:04 UTC — Heartbeat test: peer105 OK
- 21:00 UTC — Email status report sent to fausto.lelli@gmail.com
- 16:56 EDT — Watchdog v1 deployed and tested on peer105
- 16:41 EDT — Watchdog script written by earlier call_peer attempt (pre-OOM)
