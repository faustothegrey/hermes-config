Email via himalaya (virgilio→gmail, raw .eml → pipe). Quest briefs: English, structured (objective/timeline/tools/findings), sent at milestones.
§
Research Queue: YouTube→peer105, web→peer106. Max 4 video+10 web/giorno. Diurno leggero su peer70. Cron himalaya broken (usa Python smtplib invece).
§
N56VV cooling: NOTTURNO 02:00-03:00, DIURNO 11:00-19:00. Lavoro 19:00-02:00 e 03:00-11:00. peer70 (RPi H24) per carico diurno. Fix: rimosso smartctl (DISK_TEMP=N/A), ridotto snapshot da */5 a */30 per IO pressure.
§
Anomalies log ~/.hermes/anomalies/anomalies.jsonl. Watchdog auto-logs detect/resolve.
§
Quest system (quest-system skill): up to 3 quests round-robin. Advancement cron 04fd5a313c48 every 4h. Resources ~/.hermes/quest-resources.json. Status in Obsidian Hermes/Quests/. First quest: Diagram Drawing Skills for LLMs.
§
User work style: research-before-build ("first see what the world offers"). Optimize resources, don't reinvent wheels — check existing tools/peers first. Expects candor: tell them when a goal isn't clear. When a new quest arrives while one is active, ask: replace or queue?
§
Mesh peers: peer84 (N56VV, heavy work), peer70 (RPi, coordinatore, :8642 HTTP, :8643 HMP), peer105 (RPi3 YouTube), peer106 (ARM web research), peer128 (MacBook Pro :8642). Guardiano SSH locale + UPnP FritzBox 192.168.178.1:49000. WAN: diretto su :2222 o jump via peer70.
§
HMP v0.2 su peer70:8643 — task lifecycle+heartbeat. Watchdog silenzioso. Skill hmp-protocol per dettagli.
§
AgentTalk ~/Software/AgentTalk/ — TS MCP orchestratore multi-agente + client worker ~/Software/agentalk-mcp-client/ (WebSocket PTY driver per Codex/Claude/Gemini). Ruoli con session primers a chiave, wire contract SHA-256. AgentTalk ha apps/* + 8 packages.
§
AI Quota Monitoring ~/Software/scripts-ai/quota-monitoring/ — API :9899 con /tokens (Claude transcript) e /usage (Claude/Codex/Antigravity/OpenRouter %). Refresh ~2min/10min. Systemd service, env keys in ~/.env e /etc/quota-service.env.