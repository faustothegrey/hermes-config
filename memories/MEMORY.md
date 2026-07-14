Email via himalaya (virgilio→gmail, raw .eml → pipe). Quest briefs: English, structured (objective/timeline/tools/findings), sent at milestones.
§
Research Queue → dual-peer. YouTube→peer105, web→peer106. Max 4 video+10 web/giorno. Diurno leggero su peer70. BUG: cron 19c9f58c1c43 prompt usa himalaya (broken) invece di Python smtplib.
§
N56VV cooling: NOTTURNO 02:00-03:00, DIURNO 11:00-19:00. Lavoro 19:00-02:00 e 03:00-11:00. peer70 (RPi H24) per carico diurno. Fix: rimosso smartctl (DISK_TEMP=N/A), ridotto snapshot da */5 a */30 per IO pressure.
§
Anomalies at ~/.hermes/anomalies/anomalies.jsonl. Watchdog auto-logs detect/resolve.
§
Quest system (quest-system skill): up to 3 quests round-robin. Advancement cron 04fd5a313c48 every 4h. Resources ~/.hermes/quest-resources.json. Status in Obsidian Hermes/Quests/. First quest: Diagram Drawing Skills for LLMs.
§
User work style: research-before-build ("first see what the world offers"). Optimize resources, don't reinvent wheels — check existing tools/peers first. Expects candor: tell them when a goal isn't clear. When a new quest arrives while one is active, ask: replace or queue?
§
peer84 (fausto-N56VV, 192.168.178.84): heavy work node, solo cron termici/cooling. peer70 (RPi, 192.168.178.70): coordinatore mesh — heartbeats, research loop, quests, exchange su :8642, HMP v0.2 su :8643. peer105 (RPi3, YouTube), peer106 (ARM, web research), peer128 (MacBook Pro, :8642). Comunicazione peer via HTTP API su :8642. Guardiano SSH (iptables locali) + UPnP FritzBox (192.168.178.1:49000, gestito con upnpc) sono due livelli separati. Due scenari WAN: diretto su peer84:2222, o jump host via peer70 (RPi 24/7) verso peer128.
§
HMP v0.2 su peer70:8643. Task lifecycle+heartbeat, galateo, zero deps, 3 cron no_agent. Testato. Future: auth, rate limiting, failover, integrazione cron, tool MCP. Watchdog silenzioso se ok.