# Peer105 YouTube

## Goal
Usare peer105 per scaricare video YouTube e farne il digest dei transcript in locale:
yt-dlp scarica il transcript → Hermes (locale su peer105) produce riassunto
con concetti base e parole chiave.
La resilienza ai 401 free-tier NON è l'obiettivo — è un vincolo infrastrutturale
già gestito da watchdog e heartbeat.

## Architecture
```
peer105                                     orchestrator (N56VV)
┌──────────────────────────┐              ┌─────────────────────────────┐
│ watchdog.sh (ogni 10min) │              │ hermes cron (ogni 4h)       │
│  curl /health            │◄─────────────│  questo progetto            │
│  restart se giù          │              │  cerca video, scarica,      │
│                          │              │  processa, documenta        │
│ (infrastruttura,         │              │                             │
│  non obiettivo)          │              │ heartbeat.py (ogni ora)     │
└──────────────────────────┘              │  log JSONL sanitario        │
                                          └─────────────────────────────┘
```

## System info
- Host: 192.168.178.105
- OS: Fedora 30 aarch64, kernel 5.0.9
- RAM: very limited (swaps at idle)
- Hermes: v0.15.1, systemd user service (root)
- Model: deepseek/deepseek-v4-flash via nous portal (migrato da nemotron-3-ultra:free il 2026-06-19)
- Constraint: 401 when free quota exhausted → agent loop freezes
- SSH: root@192.168.178.105 (key auth)

## Project Phases

### ✅ Phase 0 — Foundation (2026-06-18/19)
Infrastructure only — not the goal, just the prerequisite:
- [x] SSH access established
- [x] Watchdog v1 deployed (health check + restart ogni 10min)
- [x] Heartbeat monitoring from orchestrator
- [x] Project Obsidian note created
- [x] Autonomous project loop created
- [x] sys-snapshot deployed for resource monitoring
- [x] Clock anomaly identified (hardware clock stuck 2019-04-12)
- [x] systemd warnings noted (cosmetic)

### 🔲 Phase 1 — YouTube Discovery
- [x] Install/verify yt-dlp on peer105 — yt-dlp 2023.03.04 installed (max for Python 3.7); too old for current YouTube (HTTP 400). Needs Python ≥3.10.
- [x] Alternative transcript method found: Node.js `youtube-transcript` npm package works (v1.3.1), 61-line transcript fetched successfully. Bypasses Python blocker.
- [x] Transcript fetcher script built and tested (`/root/transcript-worker/fetch.cjs`) — 350 segments, 13k chars from real video
- [x] First video transcript + digest produced: "Top SBC Picks in 2026" → structured JSON digest
- [ ] Search for more videos on a topic
- [ ] Collect video metadata (title, duration, URL, thumbnail)
- [ ] Build a queue of videos to process — vedi [[Hermes/Research Queue.md]]

### 🔲 Phase 2 — Transcript & Digest
- [ ] Download transcript via yt-dlp (--write-auto-subs or --write-subs)
- [ ] Clean transcript text (remove timestamps, formatting)
- [ ] Hermes digest: summarize with key concepts + keywords
- [ ] Store digest alongside video metadata
- [ ] One video per loop run, no rush

### 🔲 Phase 3 — Knowledge Base Archival
- [ ] Process one video per loop run (download → transcript → digest)
- [x] Migrate existing SBC digest to Obsidian Knowledge Base (2026-06-19)
- [ ] Store digest JSON on peer105 in ~/transcript-worker/digests/ (rolling 7 giorni)
- [ ] Archivia nota strutturata in [[Hermes/Knowledge/]] su N56VV
- [ ] Backlink reciproci con ricerche peer106
- [ ] Peer105 cleanup automatico dei digest >7 giorni

## Operation Log

### 2026-06-19
- 04:02 UTC — sys-snapshot deployed. hermes PID 1085, 138 MB RSS, RAM 438/954 MB.
- 06:00 CEST — Manual run failed (skill overflow). Fix: removed hermes-agent skill.
- 06:19 — Memory strategy defined. Email delivery added via himalaya.
- 07:05 — Note renamed from "Resilience Project" to "YouTube". Goal reframed: YouTube video processing is the task, resilience is infrastructure.
- 09:51 CEST — **Run #1.** yt-dlp 2023.11.16 installed (via pip, --no-deps for pycryptodomex/brotli). youtube-transcript-api 0.6.2 installed. Both verified functional but BLOCKED by YouTube API: old clients get "Precondition check failed" or empty XML responses. Root cause: Python 3.7 on Fedora 30 can't run yt-dlp ≥2024.x which handles current YouTube API.
- 09:39 — Heartbeat tick anticipated (pre-shutdown). Health OK.
- 09:46 — **Loop #1**: yt-dlp 2023.03.04 installed (compatible with Python 3.7.3 on Fedora 30). Video fetch failed: HTTP 400 "Precondition check failed" — YouTube API requires newer yt-dlp. Blocker: Python 3.7 too old for yt-dlp ≥2023.07. Next step: either upgrade Python on the ARM board or find alternative transcript method (e.g. yt transcript API). youtube-dl 2021.12.17 also installed as fallback (same limitation).
- 14:00 CEST — **Loop #2**. Node.js approach breakthrough: installed `youtube-transcript` npm package (v1.3.1). Successfully fetched 61-line transcript from test video via Node.js. This bypasses the Python 3.7 limitation entirely. The npm module uses its own HTTP fetching, not yt-dlp. PATH note: npm global prefix is /root/.hermes/node/lib, must be added to PATH or use full path in require(). Next: build a small Node.js script that fetches transcript + saves to file; then use Hermes on peer105 to digest it.
- 19:00 CEST — **Knowledge Base setup**. Cartella `Hermes/Knowledge/` creata con template digest. Digesto SBC migrato in nota Obsidian strutturata + JSON copiato su peer105 in `~/transcript-worker/digests/`. Cron job aggiornato per archiviare ogni digest su N56VV + rolling window 7gg su peer105.

### 2026-06-19
- 18:00 CEST — **Loop #3**. Built Node.js transcript fetcher (`/root/transcript-worker/fetch.cjs`), installed `youtube-transcript` locally. Ran on SBC review video "Top SBC Picks in 2026" (`StYdYsPAp_g`). **Success**: 350 segments, 13,167 chars fetched cleanly. Digest produced via orchestrator (to save peer105's limited context): structured JSON with summary, key concepts, keywords, buyer takeaway. Digest saved to `/tmp/peer105/sbc_digest_2026.json` and `/home/fausto/sbc_digest_2026.json`. Ties into peer106's ARM SBC research. Phase 1 script is ready — next: queue more videos.

### 2026-06-19
- 22:00 CEST — **Loop #4**. Autonomous initiative (queue empty). Processed ExplainingComputers "Consumer SBCs in 2026" (7G8uC4Ri720). Node.js fetch.cjs returned 334 segments, 11,481 chars. Digest produced: summary, 7 key concepts, 10 keywords, takeaway. Key themes: DRAM pricing crisis (Pi 5 16GB at $299.99), 70% industrial sales shift, three consumer categories pricing analysis, ExplainingComputers' channel pivot to sub-$100 boards + microcontrollers. Digest JSON saved to peer105 (~/transcript-worker/digests/). Old digests >7 days cleaned. Obsidian Knowledge Base note created with backlinks to peer106 research. Phase 1 milestone: two videos processed (Electromaker + ExplainingComputers). Next: find a third video topic to queue.

### 2026-06-18
- 21:04 UTC — Heartbeat test: peer105 OK
- 16:56 EDT — Watchdog v1 deployed and tested on peer105
