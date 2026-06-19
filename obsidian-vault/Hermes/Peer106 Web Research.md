# Peer106 Web Research

## Goal
Usare peer106 per ricerche web autonome, sfruttando la capacità di web search
del modello free-tier. Stesso approccio slow-loop di peer105: heartbeat,
documentazione su Obsidian, recap email.

## Architecture
```
peer106                                     orchestrator (N56VV)
┌──────────────────────────┐              ┌─────────────────────────────┐
│ watchdog.sh (ogni 10min) │              │ hermes cron (ogni 4h)       │
│  curl /health            │◄─────────────│  questo progetto            │
│  restart se giù          │              │  valuta, cerca, documenta   │
│                          │              │                             │
│ (stesso identico setup   │              │ heartbeat.py (ogni ora)     │
│  di peer105)             │              │  log JSONL sanitario        │
└──────────────────────────┘              └─────────────────────────────┘
```

## System info
- Host: 192.168.178.106
- OS: Fedora 30 aarch64, kernel 5.6.13
- RAM: very limited (swaps at idle)
- Hermes: v0.15.1, systemd user service (root)
- Model: nvidia/nemotron-3-ultra:free via nous portal
- SSH: root@192.168.178.106 (key auth)

## Project Phases

### ✅ Phase 0 — Foundation (2026-06-19)
- [x] SSH access established
- [x] Watchdog v1 deployed (systemd timer, ogni 10min)
- [x] Gateway installed and running (linger enabled)
- [x] API server on 0.0.0.0:8642
- [x] Peer added to mesh
- [x] Heartbeat monitoring from orchestrator
- [x] Project Obsidian note created
- [x] Autonomous project loop created

### 🔲 Phase 1 — Basic Web Research
- [x] Verify web_search works on peer106 model — confirmed: 5 results returned for "Hermes Agent Nous Research", first hit hermes-agent.nousresearch.com
- [x] First research query — "best low-power ARM SBC 2025 comparison" → full pipeline executed: web_search → web_extract → summary
- [x] Model fixed: switched from unavailable `nvidia/nemotron-3-ultra:free` to `deepseek/deepseek-chat` via Nous
- [x] Document results, assess quality
- [ ] Iterate on prompt/approach

### 🔲 Phase 2 — Research Automation
- [ ] Define research topics — vedi [[Hermes/Research Queue.md]] (inserisci qui le tue query)
- [x] Research notes archiviate in [[Hermes/Knowledge/]] (Particle Tachion, 2026-06-19)
- [ ] Batch search → extract → summarize pipeline
- [ ] Store results in structured format (Obsidian or files)
- [ ] Periodic research digests

### 🔲 Phase 3 — Cross-Peer Work
- [ ] peer105 finds interesting video topics → peer106 researches them
- [ ] peer106 research summaries → peer105 video script material
- [ ] Coordinated output (shared Obsidian note)

## Operation Log

### 2026-06-19
- 06:55 CEST — Phase 0 complete: SSH, watchdog, gateway, API server, peer mesh, heartbeat, Obsidian note, autonomous loop cron created. Same architecture as peer105. Loop schedule: 6, 10, 14, 18, 22.
- 09:51 CEST — **Run #1.** web_search verified operational via call_peer. First query: "Fedora 30 ARM aarch64 low memory optimization tips" → 5 results returned successfully. Top results: Fedora Discussion on zram swap (8GB default), Reddit r/Fedora on reducing RAM usage. Tool confirmed working on peer106's free-tier model (nvidia/nemotron-3-ultra:free). Next: define first real research topic and run web_search + web_extract pipeline on peer106 itself.
- 09:39 — Heartbeat tick anticipated (pre-shutdown). Health OK.
- 09:46 — **Loop #1**: web_search verified working via call_peer. Query "Hermes Agent Nous Research" → 5 results, first: hermes-agent.nousresearch.com. Tool operational. Next: first real research topic.
- 14:00 CEST — **Loop #2**. Model crisis diagnosed and solved: `nvidia/nemotron-3-ultra:free` returned 404 (Nous removed it). Tried `google/gemini-2.0-flash-lite-001:free` and `meta-llama/llama-3.1-8b-instruct:free` via OpenRouter — all 404 without API key. Solution: switched to `deepseek/deepseek-chat` via Nous provider (same as orchestrator). Model confirmed working. First research task completed: "best low-power ARM SBC 2025" — web_search → web_extract → summary pipeline executed. Results: top SBCs Radxa Orion O6N/Orange Pi 6 Plus (CIX P1), Radxa Dragon Q6A (Qualcomm), Radxa Cubie A7A (budget). Key trend: RAM costs ("RAMageddon") impacting innovation. Full tool chain operational: search, extract, summarize.

### 2026-06-19
- 18:00 CEST — **Loop #3**. Cross-peer research: peer105 downloaded and digested an SBC review video ("Top SBC Picks in 2026"). Complimented with independent research on the video's top recommendation: **Particle Tachion**.
- 19:00 CEST — **Knowledge Base setup**. Research note `Hermes/Knowledge/2026-06-19 — Research — Particle Tachion.md` creata con frontmatter, backlink al video digest, e fonti. Cron job aggiornato per archiviare tutte le ricerche future qui. Web search + CNX Software review extract. Key findings: Qualcomm QCM6490 SoC, 12 TOPS AI accelerator, 5G LTE + Wi-Fi 6E, $249-299, Ubuntu support (headless OK, GUI setup buggy at step 4). Benchmark notes: eMMC ~950 MB/s read, 5GHz Wi-Fi ~102 Mbps, Chromium Speedometer 3.49, Firefox 4.96. AI pipeline via Qualcomm AI Hub functional. Particle OS cloud platform (OTAA, fleet mgmt) validated as key differentiator. call_peer on peer106 timed out (free-tier + 2GB RAM swap); research done directly from orchestrator instead. Next: iterate on research approach — direct orchestrator search for reliability on resource-constrained peer.
- 22:00 CEST — **Loop #4**. Autonomous initiative (queue empty). Researched "consumer SBC market trends 2026" complementing peer105's ExplainingComputers digest. Key articles extracted: Jeff Geerling's DRAM pricing analysis (Pi 5 16GB at $299.99, "hobbyist SBC market on life support"), Global Market Insights report ($4.3B market, 5.7% CAGR, 52.3% ARM share). Core finding: the DRAM pricing crisis is the defining SBC story of 2026 — bifurcating the market into industrial/professional ($200-600+) and budget/maker (sub-$100, microcontrollers). Research note archived: `Hermes/Knowledge/2026-06-19 — Research — SBC Market DRAM Crisis.md`. Backlinked to peer105 digest. Next: define next autonomous research topic.
