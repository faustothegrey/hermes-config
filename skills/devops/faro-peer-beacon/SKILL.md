---
name: faro-peer-beacon
description: "Protocollo minimale per sapere chi è online e chi no nella peer mesh Hermes. Tre tipi di peer: LED (beacon-only), portatile (macOS + App Nap), sempre acceso (Raspberry Pi con gateway Hermes)."
version: 2.0.0
author: Hermes Agent
platforms: [linux, macos]
---

# Faro — Peer Beacon Protocol

Protocollo minimale per sapere chi è online e chi no nella peer mesh Hermes.

## Architettura

```
┌─────────────────────┐                  ┌──────────────────────────┐
│  peer105/106         │  beacon HTTP     │                          │
│  (ARM Fedora,        │ ── GET /beacon/─→│  N56VV (orchestratore)   │
│   @reboot cron)      │                  │                          │
│                     │                  │  beacon-listener :9191   │
│  peer128 (MacBook)   │  cron */2 ──────→│  faro-monitor cron */5   │
│  (portatile, App Nap)│  detect reconnect│  → status.json           │
│                     │                  │                          │
│  keepalive pull      │ ←─ cron 1m ─────│  (previene App Nap)      │
│  (da orchestr.)      │  curl /health   │                          │
│                     │                  │                          │
│  peer70 (Raspberry)  │  ─── full HTTP ─→│  poll /health cron */5   │
│  (24/7, gateway live)│  mesh MCP        │  + peer mesh             │
└─────────────────────┘                  └──────────────────────────┘
```

## Tipi di peer

### LED (Beacon-only — 105, 106)
- ARM SBC con risorse minime (Fedora 30, <1GB RAM)
- Solo SSH + beacon.sh — zero servizi Hermes
- Beacon `@reboot` via crontab, stupido (una riga di curl)
- Monitoraggio passivo ogni 5 min dall'orchestratore
- **Nessun keepalive** — la macchina è fissa e non va in sleep

### Portatile (macOS — 128)
- MacBook con Hermes gateway via Tunnel SSH
- App Nap può sospendere Hermes tra beacon → beacon ogni 2 min + keepalive pull ogni 1 min
- Keepalive pull orchestratore → peer (no_agent, curl /health)
- Vedi `references/macos-keepalive.md`

### Sempre acceso (Raspberry Pi / SBC — peer70)
- RPi / SBC con Hermes installato e gateway attivo 24/7
- Zero problemi termici (consumi irrisori, nessuna cooling window)
- **Non serve beacon.sh** — il gateway Hermes espone già /health
- Monitoraggio passivo via /health ogni 5 min (come gli altri)
- Può partecipare alla peer mesh come nodo completo se api_server abilitato
- Ideale per carico diurno leggero mentre N56VV è in cooling period

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
  - peer105/106: nessun /health → beacon listener
  - peer128: via tunnel SSH :18642/health
  - peer70: http://192.168.178.70:8642/health (solo se api_server attivo)
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

## Workload distribution (N56VV + peer70)

Con l'arrivo di peer70 (Raspberry Pi 24/7), il carico si ridistribuisce:

| Periodo | N56VV (portatile) | peer70 (Raspberry) | peer105/106 |
|---|---|---|---|
| 🏠 Notte (02-04:00) | Cooling | Web/API/bridge | — |
| 🌅 Mattina (04-12:00) | Lavoro pesante | Web/API/bridge | Ricerca video/web |
| ☀️ Pomeriggio (12-16:00) | Cooling | Web/API/bridge | Ricerca video/web |
| 🌆 Sera (16-02:00) | Lavoro pesante | Web/API/bridge | — |

peer70 non ha cooling window — lavora sempre. Il lavoro pesante (ricerca video, processi lunghi) resta su N56VV quando non è in cooling.

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
# Peer LED (Linux ARM — 105/106):
scp beacon.sh root@<peer>:/root/.hermes/scripts/beacon.sh
ssh root@<peer> "(crontab -l 2>/dev/null; echo '@reboot /root/.hermes/scripts/beacon.sh <nome> once') | crontab -"

# Peer portatile (macOS — 128):
scp beacon-macos.sh user@<peer>:~/.hermes/scripts/beacon.sh
ssh user@<peer> "(crontab -l 2>/dev/null; echo '*/2 * * * * ~/.hermes/scripts/beacon.sh') | crontab -"

# Keepalive pull (solo macOS — previene App Nap):
# Creare cron job no_agent sull'orchestratore: ogni 1-2 min, curl /health del peer

# Peer sempre acceso (Raspberry Pi — peer70):
# No beacon.sh necessario. Se api_server abilitato su peer70:
#   1. Aggiungere a peer-mesh.yaml su N56VV
#   2. Associare API key
#   3. Verificare: curl http://192.168.178.70:8642/health
#   4. Il monitor passivo lo trova da solo
# Verifica base senza api_server:
#   ssh fausto@<ip> "hermes status"
#   cat ~/.hermes/gateway_state.json | grep gateway_state
```

## Abilitare api_server su un peer sempre acceso (peer70)

Se il peer RPi deve partecipare alla peer mesh come nodo full Hermes:

```bash
# 1. Sul peer70, aggiungere a config.yaml:
#    api_server:
#      enabled: true
#      host: 0.0.0.0
#      port: 8642

# 2. Creare ~/.hermes/.env con:
#    API_SERVER_KEY=<chiave>
#    API_SERVER_HOST=0.0.0.0

# 3. Riavviare il gateway:
#    systemctl --user restart hermes-gateway
#    oppure kill gateway PID e riavviare manualmente

# 4. Da N56VV, verificare:
#    curl -H "Authorization: Bearer $CHIAVE" http://192.168.178.70:8642/v1/capabilities
```

Dopo l'abilitazione, peer70 appare automaticamente in `mcp_hermes_peers_list_peers` e può ricevere chiamate `call_peer` / `start_peer_run`.

## Note importanti
- I peer 105/106 hanno hostname `localhost` — usare nome esplicito via argomento
- Il beacon è volutamente **stupido**: non fa retry, non logga errori, non consuma risorse
- Se il beacon fallisce, il monitor passivo lo becca tra 5 min via /health
- La transizione online→offline è rilevata dal monitor passivo (3 fallimenti consecutivi = offline)
- **Peer macOS (peer128):** App Nap può sospendere Hermes anche tra un beacon e l'altro. Servono keepalive pull dall'orchestratore ogni 1-2 minuti. Vedi `references/macos-keepalive.md` per dettagli.
- **Peer RPi (peer70):** nessun bisogno di keepalive o beacon.sh. È sempre acceso. Se Hermes crasha, il monitor passivo lo rileva entro 5 min.
- **Frequenza polling:** Linux peers (105/106) → beacon `@reboot` + monitor passivo ogni 5 min. macOS peers (128) → beacon ogni 2 min + keepalive pull ogni 1 min dall'orchestratore. RPi (70) → monitor passivo ogni 5 min via /health.

## Riferimenti
- `references/peer-installation.md` — comandi specifici per ogni peer installato
- `references/macos-keepalive.md` — keepalive pull per evitare App Nap su macOS
- `scripts/beacon.sh` — beacon script per Linux ARM
- `scripts/beacon-macos.sh` — beacon script per macOS
- `scripts/faro-monitor.sh` — monitor passivo (eseguito da cron sull'orchestratore)
