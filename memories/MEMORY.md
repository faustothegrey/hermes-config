Email via himalaya (virgilio→gmail, raw .eml → pipe). Quest briefs: English, structured (objective/timeline/tools/findings), sent at milestones.
§
Research Queue → dual-peer. YouTube→peer105, web→peer106. Max 4 video+10 web/giorno. Diurno leggero su peer70. BUG: cron 19c9f58c1c43 prompt usa himalaya (broken) invece di Python smtplib.
§
N56VV cooling: NOTTURNO 02:00-03:00 (rtcwake), DIURNO 11:00-19:00. Lavoro 19:00-02:00 e 03:00-11:00. Da peer70 (RPi H24) carico diurno leggero. Fix 2026-07-01: rimosso smartctl da cooling-stats.sh (DISK_TEMP=N/A) e ridotto snapshot^M da */5 a */30 — causava IO pressure e calore dopo boot.
§
Anomalies at ~/.hermes/anomalies/anomalies.jsonl. Watchdog auto-logs detect/resolve.
§
"apriti sedano" → 2222+3001 per 20 min (locale/LAN). Forwarding esterno su peer70. Keepalive: "Sisisi" resetta +20 min.
§
Quest system (quest-system skill): up to 3 quests round-robin. Advancement cron 04fd5a313c48 every 4h. Resources ~/.hermes/quest-resources.json. Status in Obsidian Hermes/Quests/. First quest: Diagram Drawing Skills for LLMs.
§
User work style: research-before-build ("first see what the world offers"). Optimize resources, don't reinvent wheels — check existing tools/peers first. Expects candor: tell them when a goal isn't clear. When a new quest arrives while one is active, ask: replace or queue?
§
Peer128 MacBook Pro 192.168.178.128, SSH fausto@ key-auth. API diretta su :8642 — tunnel SSH (:18642) non più necessario. Cron 2m keepalive. peer-mesh su 192.168.178.128:8642.
§
Comunicazione tra peer solo via API su :8642 — niente SSH tunnel. Peer mesh sempre via HTTP API.
§
This machine = peer84 (fausto-N56VV, 192.168.178.84). Heavy work node. Coordinatore mesh = peer70 (192.168.178.70, RPi). N56VV/peer84 tiene solo cron termici/cooling. Tutta l'infrastruttura peer (heartbeats, research loop, quests, exchange) su peer70 via api_server :8642.
§
AgentTalk research agenda: ~/research-agenda copy.md (11 Qs). Q0 prior-art survey active: Traycer done (digest in Knowledge/), MetaGPT next at 20:00 tick. One step per tick, ARM friends.