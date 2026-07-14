---
name: hmp-protocol
description: "Hermes Mesh Protocol (HMP) — protocollo di comunicazione pull-based tra agenti Hermes su LAN con SQLite, heartbeat progress, galateo strutturato e failover-ready."
version: 0.2.1
author: Fausto + peer70
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [hmp, protocol, peer-mesh, agent-communication, sqlite, heartbeat]
---

# HMP — Hermes Mesh Protocol

Protocollo di comunicazione tra agenti Hermes su LAN. Pull-based, SQLite persistente, heartbeat progress, galateo strutturato.

## Quando caricarlo

Carica questa skill quando il task riguarda:
- Comunicazione strutturata tra peer Hermes
- Progettazione o modifica del protocollo HMP
- Implementazione di hmp.py (bus, server, client)
- Integrazione di un nuovo peer nel mesh HMP
- Migrazione cluster o failover
- Diagnostica del server HMP su peer70

## Riferimenti

- `references/HMP-SPEC-v0.2.md` — specifica completa del protocollo
- `references/deployment-round-1.md` — deploy notes, bug fix, test results e cluster state
- `scripts/hmp.py` — implementazione Python del bus, server e client (stdlib-only, ~27KB)
- `templates/hmp-config.json` — template configurazione per peer70
- `templates/hmp-config.json` — template configurazione per peer70

## Architettura sintetica

- **Bus**: SQLite WAL su peer70 (primary)
- **Server HMP**: HTTP su :8643 (porta separata dalla API Hermes su :8642)
- **Trasporto messaggi**: HTTP POST/GET via HMPClient (urllib, stdlib)
- **Lifecycle**: pending → queued → delivered → working → completed/failed/needs_input/timed_out/cancelled
- **Heartbeat**: progress update ogni 5-10s con progress_pct (task lineari) o has_progress=false (esplorativi)
- **Galateo**: una richiesta per messaggio, ACK obbligatorio entro 5s, scope minimo, auto-limitazione quantitativa, idempotenza
- **Discovery**: Agent Card HTTP su `/hmp/agent-card` con skills, constraints, rate_limits, availability_window, cluster_role

## Task lifecycle completo

```
pending ──→ queued ──→ delivered ──→ working ──→ completed
  │           │            │            │
  │           │            ├──→ failed  └──→ needs_input ──→ working (reprise)
  │           │            │
  │           │            └──→ timed_out
  │           │
  └──→ cancelled           └──→ cancelled
```

## Formato messaggio

Ogni messaggio ha: hmp_version, message_id, idempotency_key, from, to, type, timestamp, payload.
Modalità full (CREATE/UPDATE) e lightweight (heartbeat/delta).

## Galateo (10 regole)

1. Una richiesta per messaggio
2. ACK obbligatorio entro 5s
3. Idempotenza (idempotency_key)
4. Scope minimo
5. Timeout realistico e negoziato
6. Output format dichiarato
7. Niente ping-pong in needs_input
8. Auto-limitazione quantitativa
9. Priorità low/normal/high
10. Non interrompere senza cancel esplicito

## Deploy attuale

| Componente | Dove | Dettaglio |
|---|---|---|
| hmp.py | peer70: ~/.hermes/skills/.../hmp-protocol/scripts/hmp.py | Python 3.9.2 |
| Server HMP | peer70:8643 | `nohup python3 hmp.py 8643` |
| DB | peer70: ~/.hermes/data/hmp/agent_messages.db | SQLite WAL |
| Config | peer70: ~/.hermes/hmp-config.json | peer_name=peer70, cluster_role=primary |
| Cron message-router | ogni 30s, no_agent | pending → queued → delivered |
| Cron watchdog | ogni 2 min, no_agent | timed_out su heartbeat >5min fermi |
| Cron dream-engine | 02:00 CEST, no_agent | compact + archive >30gg |

### Cron su peer70 via SSH wrapper

I cron HMP girano su peer70 ma sono registrati su peer84 (orchestratore). Usano script wrapper SSH in `~/.hermes/scripts/`:

```
hmp-remote-message-router.sh  →  ssh fausto@peer70 "cd ~/.hermes && python3 scripts/hmp-message-router.py"
hmp-remote-watchdog.sh        →  ssh fausto@peer70 "cd ~/.hermes && python3 scripts/hmp-watchdog.py"
hmp-remote-dream-engine.sh    →  ssh fausto@peer70 "cd ~/.hermes && python3 scripts/hmp-dream-engine.py"
```

Prerequisito: SSH key auth funzionante da orchestrator a peer70.

### Verifica rapida

```bash
# Agent Card
curl -s http://192.168.178.70:8643/hmp/agent-card

# Invia messaggio (da peer84)
python3 -c "
import sys; sys.path.insert(0,'/home/fausto/.hermes/skills/autonomous-ai-agents/hmp-protocol/scripts')
from hmp import HMPClient, new_message_id, now_iso
c = HMPClient('http://192.168.178.70:8643')
r = c.send_message({'hmp_version':'1.0','message_id':new_message_id(),'idempotency_key':new_message_id(),'from':'peer84','to':'peer70','type':'request','timestamp':now_iso(),'payload':{'task_type':'ping'}})
print(r)
"

# Poll messaggio
python3 -c "
import sys; sys.path.insert(0,'/home/fausto/.hermes/skills/autonomous-ai-agents/hmp-protocol/scripts')
from hmp import HMPClient
c = HMPClient('http://192.168.178.70:8643')
print(c.poll_message('MSG_ID'))
"

# DB diretto su peer70
ssh fausto@192.168.178.70 'python3 /tmp/hmp-show.py'
```

## Cluster

Attualmente: primary = peer70, SPOF accettato per prototipo.
Futuro: replica su peer128 via storage condiviso (NFS/sshfs/DRBD).
cluster_role in Agent Card: primary / replica / observer.

## Pitfall — expanduser in HMPBus

`HMPBus.__init__` fa `os.path.expanduser()` sul path del DB. Se il path contiene `~` non espanso (es. `~/.hermes/data/hmp/agent_messages.db` dal config JSON), il costruttore lo espande correttamente.

Attenzione: se si crea un HMPBus con un path raw senza chiamare il costruttore, il `~` non viene espanso e si finisce con un DB separato in `~/` letterale nella CWD.

Verifica: quando i cron script dicono "idle" ma il DB ha messaggi in pending, confronta il path del bus con il path atteso.

## Come iniziare (da zero)

1. Su peer70: copia `scripts/hmp.py` in `~/.hermes/skills/.../hmp-protocol/scripts/`
2. Crea `~/.hermes/hmp-config.json` dal template
3. Avvia server: `nohup python3 hmp.py 8643 < /dev/null > ~/.hermes/data/hmp/server.log 2>&1 & disown`
4. Verifica: `curl -s http://peer70:8643/hmp/agent-card`
5. Crea cron wrapper script SSH su orchestratore
6. Registra cron: `hmp-message-router` (30s), `hmp-watchdog` (2m), `hmp-dream-engine` (02:00)
7. Test: invia messaggio da orchestratore, polla per verificare