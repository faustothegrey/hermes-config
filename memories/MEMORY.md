Email via himalaya (virgilio→gmail, raw .eml → pipe). Quest briefs: English, structured (objective/timeline/tools/findings), sent at milestones.
§
Peer105/106 ARM Fedora30 risorse minime, SSH root. Faro beacon: beacon-listener N56VV:9191, cron */5 monitor, ~/.hermes/peer-status/. beacon.sh su 105/106 (@reboot), peer128 (cron */2 con detection LAN). Skill: faro-peer-beacon.
§
Research Queue → dual-peer. YouTube/video→peer105, web→peer106. Loop manda email via himalaya. Ritmo max 4 video + 10 articoli/giorno. DA peer70 IN POI: lavoro diurno leggero (web, API, bridge) va su peer70 24/7.
§
N56VV cooling: NOTTURNO 02:00-03:00 (rtcwake), DIURNO 11:00-19:00. Lavoro 19:00-02:00 e 03:00-11:00. Da peer70 (RPi H24) carico diurno leggero. Fix 2026-07-01: rimosso smartctl da cooling-stats.sh (DISK_TEMP=N/A) e ridotto snapshot^M da */5 a */30 — causava IO pressure e calore dopo boot.
§
Anomalies at ~/.hermes/anomalies/anomalies.jsonl. Watchdog auto-logs detect/resolve.
§
"apriti sedano" → 2222+3001 per 20 min (locale/LAN). Forwarding esterno su peer70. Keepalive: "Sisisi" resetta +20 min.
§
Quest system (skill: quest-system). Up to 3 parallel quests, round-robin. Advancement cron job_id:04fd5a313c48 every 4h. Resources ~/.hermes/quest-resources.json (peer105 4vids/day, peer106 10searches/day). Status in Obsidian Hermes/Quests/<quest>.md. First quest: Diagram Drawing Skills for LLMs.
§
User work style: research-before-build ("first see what the world offers"). Optimize resources, don't reinvent wheels — check existing tools/peers first. Expects candor: tell them when a goal isn't clear. When a new quest arrives while one is active, ask: replace or queue?
§
Peer128 MacBook Pro 192.168.178.128, SSH fausto@ key-auth. API diretta su :8642 — tunnel SSH (:18642) non più necessario. Cron 2m keepalive. peer-mesh su 192.168.178.128:8642.
§
Peer70: Raspberry Pi 192.168.178.70, Debian 11, 3.7GB RAM, 59GB disk. SSH fausto@ id_rsa. Hermes v0.17.0, gateway Telegram 24/7, api_server attivo su :8642. Ponte esterno + carico diurno leggero. Tutta la comunicazione peer via API.
§
Comunicazione tra peer solo via API su :8642 — niente SSH tunnel. Peer mesh sempre via HTTP API.