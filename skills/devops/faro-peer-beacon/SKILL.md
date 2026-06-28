# Faro — Peer Beacon Protocol

Protocollo minimale per sapere chi è online e chi no nella peer mesh Hermes.

## Architettura

```
┌─────────────────┐     beacon HTTP      ┌──────────────────┐
│  peer105/106     │ ─── GET /beacon/ ──→ │                  │
│  (fissi, @reboot)│                      │  N56VV (orchestr.)│
│                  │                      │                  │
│  peer128 (MBP)   │ ─── cron */2 ──────→ │  beacon-listener │
│  (portatile)     │   detect reconnect   │  :9191           │
│                  │                      │  + faro-monitor  │
│                  │                      │  cron */5        │
│                  │                      │  → status.json   │
│                  │                      │                  │
│  keepalive pull  │ ←─ cron 1m ─────────│  (previene       │
│  (da orchestr.)  │   curl /health      │   App Nap su MBP)│
└──────────────────┘                      └──────────────────┘
```

## Componenti

### 1. Beacon Listener (N56VV)
- `~/.hermes/scripts/beacon-listener.py`
- Server HTTP minimale su porta 9191
- Endpoint: `GET /beacon/<peer_name>` → scrive su beacon.log
- Endpoint: `GET /health` → health check
- Auto-rotate log a 2000 linee
- Riavvio automatico: watchdog nel monitor cron, e @reboot via crontab

### 2. Monitor Passivo (N56VV)
- `~/.hermes/scripts/faro-monitor.sh`
- Cron job: `*/5 * * * *`
- Polla `/health` di tutti i peer (timeout 10s)
- Rileva transizioni online↔offline → `transitions.jsonl`
- Aggiorna `~/.hermes/peer-status/status.json`
- Include watchdog per il beacon-listener (lo riavvia se morto)

### 3. Beacon Script — Peer Fissi (105/106)
- `beacon.sh <peer_name> once` 
- Copiato in `/root/.hermes/scripts/beacon.sh` via root SSH
- Cron `@reboot` — invia un singolo curl al listener
- Stupido e leggero: una riga di curl, zero log, zero lock

### 4. Beacon Script — Peer Portatile (128, MacBook)
- `beacon.sh` (versione macOS, copiata come beacon.sh su peer128)
- Cron `*/2 * * * *` — esegue ogni 2 minuti
- Rileva se l'orchestratore è raggiungibile
- Se raggiungibile e prima non lo era → invia beacon
- Usa `/tmp/faro-peer128.lock` per tracciare stato precedente
- Logga su `~/.hermes/peer-status/beacon-client.log`

### 5. Keepalive Pull — Peer macOS (128)
- Cron job `every 1m` dall'orchestratore verso il peer
- `curl -s --connect-timeout 5 http://<peer-ip>:8642/health`
- Previene App Nap che sospende Hermes tra beacon push
- Zero token (no_agent=true), file `references/macos-keepalive.md`

### 6. Query rapida
- `python3 ~/.hermes/scripts/faro.py` — riepilogo stato peer
- `python3 ~/.hermes/scripts/faro.py --online` — solo online
- `python3 ~/.hermes/scripts/faro.py --offline` — solo offline

## Directory dei dati
```
~/.hermes/peer-status/
├── status.json          # Stato corrente (aggiornato ogni 5min)
├── transitions.jsonl    # Log delle transizioni online↔offline
├── beacon.log           # Beacon ricevuti dai peer
└── .previous-state.json # Stato precedente (per rilevare transizioni)
```

## Installazione su nuovo peer
```bash
# Peer fisso (Linux ARM):
scp beacon.sh root@<peer>:/root/.hermes/scripts/beacon.sh
ssh root@<peer> "(crontab -l 2>/dev/null; echo '@reboot /root/.hermes/scripts/beacon.sh <nome> once') | crontab -"

# Peer portatile (macOS):
scp beacon-macos.sh user@<peer>:~/.hermes/scripts/beacon.sh
ssh user@<peer> "(crontab -l 2>/dev/null; echo '*/2 * * * * ~/.hermes/scripts/beacon.sh') | crontab -"

# Keepalive pull (opzionale per macOS — previene App Nap):
# Creare cron job no_agent sull'orchestratore: ogni 1-2 min, curl /health del peer
```

## Note importanti
- I peer 105/106 hanno hostname `localhost` — usare nome esplicito via argomento
- Il beacon è volutamente **stupido**: non fa retry, non logga errori, non consuma risorse
- Se il beacon fallisce, il monitor passivo lo becca tra 5 min via /health
- La transizione online→offline è rilevata dal monitor passivo (3 fallimenti consecutivi = offline)
- **Peer macOS (peer128):** App Nap può sospendere Hermes anche tra un beacon e l'altro. Servono keepalive pull dall'orchestratore ogni 1-2 minuti. Vedi `references/macos-keepalive.md` per dettagli.
- **Frequenza polling:** Linux peers (105/106) → beacon `@reboot` + monitor passivo ogni 5 min. macOS peers (128) → beacon ogni 2 min + keepalive pull ogni 1 min dall'orchestratore.
