Email via himalaya (virgilio→gmail, raw .eml → pipe). Quest briefs: English, structured (objective/timeline/tools/findings), sent at milestones.
§
Peer105/106 ARM Fedora30 risorse minime, SSH root. Faro beacon: beacon-listener N56VV:9191, cron */5 monitor, ~/.hermes/peer-status/. beacon.sh su 105/106 (@reboot), peer128 (cron */2 con detection LAN). Skill: faro-peer-beacon.
§
Research Queue [[Hermes/Research Queue.md]] → loop dual-peer. YouTube/video→peer105, web→peer106. Loop manda email riepilogo a gmail via himalaya. Trigger: "aggiungi temi". Ritmo max 4 video + 10 articoli/giorno.
§
N56VV: COOLING WINDOW 02:00-04:00 (notturno, 2h) + 12:00-16:00 (diurno, 4h) — Opzione A. Ventola USB 22-Giu. Freeze oltre 95°C. Baseline 81°C idle. Stats ~/.hermes/cooling-stats/. Cron report termico: notturno job_id:3d9f08a47adf (04:10), diurno job_id:81db87817660 (16:10), entrambi virgilio→gmail. Cooling period ha precedenza su ogni altro cron job.
§
Anomalies at ~/.hermes/anomalies/anomalies.jsonl (JSONL start/resolve events, timestamp, reason, duration). Watchdog auto-logs detection & resolution.
§
Frase magica "apriti sedano" → apre 2222 + 3001 per 20 min. Keepalive: utente risponde "Sisisi" su Telegram per resettare timer +20 min.
§
Quest system (skill: quest-system). Up to 3 parallel quests, round-robin. Advancement cron job_id:04fd5a313c48 every 4h. Resources ~/.hermes/quest-resources.json (peer105 4vids/day, peer106 10searches/day). Status in Obsidian Hermes/Quests/<quest>.md. First quest: Diagram Drawing Skills for LLMs.
§
User work style: research-before-build ("first see what the world offers"). Optimize resources, don't reinvent wheels — check existing tools/peers first. Expects candor: tell them when a goal isn't clear. When a new quest arrives while one is active, ask: replace or queue?
§
peer128 MacBook Pro 192.168.178.128, SSH fausto@ key-auth. Tunnel SSH da N56VV (:18642→:8642) bypassa blocco TCP macOS. agent-bus plist CANCELLATO (non .disabled — macOS ripristina). Cron 2m keepalive. ProcessType: Background. peer-mesh su 127.0.0.1:18642. TODO: sudo tmutil disable + backup 312GB.