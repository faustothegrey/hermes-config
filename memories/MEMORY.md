Peer128: MBP Fausto 192.168.178.128:8642, SSH fausto+id_rsa OK, API OK. OpIndex: [[Hermes/Overview]], [[Projects/ScienceClick2]]. Cron/loop in Obsidian. MEMORY.md e USER.md in ~/.hermes/memories/ (entry separate da §).
§
"Mandami una email" = usa himalaya message send con raw message (From: fausto.lelli@virgilio.it, To: fausto.lelli@gmail.com). Scrivi il contenuto in /tmp/*.eml, poi `cat /tmp/file.eml | himalaya message send -- -`. Account virgilio configurato e funzionante.
§
Memory 5-layer: HOT (built-in), WARM (Holographic HRR+SQLite attivo 2026-06-19), COLD (session_search), PROCEDURAL (skills), VAULT (Obsidian). Rollback: hermes memory off. Dettagli in skill hermes-memory-architecture.
§
Peer105 e Peer106 sono host con risorse estremamente ristrette. Quando installo qualcosa di nuovo (pacchetti, dipendenze, tool) su questi host devo tenere d'occhio il carico di sistema (load, RAM, I/O) e non saturarli. Privilegiare installazioni leggere e sequenziali, mai in parallelo.
§
PRINCIPIO FONDAMENTALE: prima di qualsiasi azione (tool call, comando, API call), controllare SEMPRE le fonti di conoscenza esistenti in quest'ordine: (1) memoria HOT (memory tool), (2) memoria WARM (fact_store — probe/reason), (3) session_search, (4) Obsidian vault (~/Documents/Obsidian Vault/). Solo se l'informazione manca o è palesemente datata, procedere con indagini live. Se è datata, chiedere conferma all'utente prima di agire. Questo evita di rifare lavoro già fatto.
§
Research Queue in Obsidian [[Hermes/Research Queue.md]]: input per il loop dual-peer. YouTube URL → peer105, `web "query"` → peer106. Ritmo: 3-4 video/giorno, ~10 articoli/giorno su peer105/106. Niente batch pesanti.