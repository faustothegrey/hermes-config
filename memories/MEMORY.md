Peer128: MBP Fausto 192.168.178.128:8642, SSH fausto+id_rsa OK, API OK. OpIndex: [[Hermes/Overview]], [[Projects/ScienceClick2]]. Cron/loop in Obsidian. MEMORY.md e USER.md in ~/.hermes/memories/ (entry separate da §).
§
"Mandami una email" = usa himalaya message send con raw message (From: fausto.lelli@virgilio.it, To: fausto.lelli@gmail.com). Scrivi il contenuto in /tmp/*.eml, poi `cat /tmp/file.eml | himalaya message send -- -`. Account virgilio configurato e funzionante.
§
Memory 5-layer (HOT/WARM/COLD/PROCEDURAL/VAULT). Dettagli skill hermes-memory-architecture. Rollback: hermes memory off.
§
Peer105 e Peer106 sono host con risorse estremamente ristrette. Quando installo qualcosa di nuovo (pacchetti, dipendenze, tool) su questi host devo tenere d'occhio il carico di sistema (load, RAM, I/O) e non saturarli. Privilegiare installazioni leggere e sequenziali, mai in parallelo.
§
Prima di agire: check (1) HOT memory, (2) WARM fact_store, (3) session_search, (4) Obsidian vault. Solo se manca/datata → live. Conferma utente se datata.
§
Research Queue [[Hermes/Research Queue.md]] → loop dual-peer. YouTube/video→peer105, web→peer106. Loop manda email riepilogo a gmail via himalaya. Trigger: "aggiungi temi". Ritmo max 4 video + 10 articoli/giorno.
§
N56VV freeze = thermal overload (CPU 95°C+). Fix: clean heatsink+fan, repaste thermal paste.
§
N56VV cooling 01-06 ogni notte. Stats pre/post in ~/.hermes/cooling-stats/. Report 06:10.
§
Anomalie watchdog su ~/.hermes/anomalies/anomalies.jsonl (JSONL: eventi start/resolve con timestamp, motivi, durata). Watchdog modificato per loggare automaticamente ogni anomalia all'inizio e alla risoluzione. Per consultare anomalie passate basta chiedere.