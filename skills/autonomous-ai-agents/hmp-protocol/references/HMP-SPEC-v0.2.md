# Hermes Mesh Protocol (HMP) — SPEC v0.2

> Protocollo di comunicazione tra agenti Hermes su LAN.
> Pull-based, SQLite persistente, heartbeat progress, galateo strutturato.
> Feedback integrato da peer70 (peer review round 1).

---

## 1. Principi

- **Una richiesta per messaggio** — niente liste di domande
- **Scope esplicito** — l'emittente dichiara cosa vuole e in che formato
- **Heartbeat progress** — il ricevente aggiorna lo stato mentre lavora
- **ACK obbligatorio** — ogni messaggio va confermato; senza ACK il mittente re-invia
- **Timeout negoziato** — handshake iniziale, non valore fisso
- **Senza blocco** — nessun agente aspetta in idle: pollla o usa eventi
- **Idempotenza** — ogni messaggio ha una chiave univoca; duplicati ignorati
- **Failover-ready** — SQLite locale ora, migrazione a cluster documentata, cluster_role già in Agent Card

---

## 2. Architettura

```
┌─────────────────────────────────────────────────┐
│                  peer70 (coordinatore, primary)  │
│  ┌──────────────────────────────────────────┐   │
│  │   agent_messages.db (SQLite WAL)         │   │
│  │   hmp_mcp_server.py → MCP tools          │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │   cron: hmp-message-router (30s)         │   │
│  │   cron: hmp-watchdog (2m)               │   │
│  │   cron: hmp-dream-engine (02:00 CEST)   │   │
│  └──────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────┘
                       │ HTTP :8642
         ┌─────────────┼─────────────┐
         │             │             │
      peer84        peer105       peer106
    (worker)        (worker)      (worker)
```

**Ora:** SQLite su peer70 (primary).  
**Futuro (migrazione cluster):** SQLite su storage condiviso accessibile da ≥2 coordinatori. Vedi §7.

**cluster_role** definito in Agent Card: `primary` | `replica` | `observer`. peer70 = primary. Futuro secondo coordinatore = replica.

---

## 3. Task Lifecycle

### Stati

```
pending ──→ queued ──→ delivered ──→ working ──→ completed
  │           │            │            │
  │           │            ├──→ failed  └──→ needs_input ──→ working (reprise)
  │           │            │
  │           │            └──→ timed_out
  │           │
  └──→ cancelled           └──→ cancelled
```

| Stato | Descrizione |
|---|---|
| `pending` | Messaggio creato, non ancora preso in carico dal router |
| `queued` | Preso in carico dal router, in attesa di scheduling |
| `delivered` | Letto dal destinatario, accettato, ACK inviato |
| `working` | In elaborazione. Il destinatario aggiorna `progress` periodicamente |
| `completed` | Task finito, output disponibile in `result` |
| `failed` | Errore irrecoverabile. Campo `cause` obbligatorio |
| `needs_input` | Il destinatario ha bisogno di chiarimenti. Campo `reason` obbligatorio |
| `timed_out` | L'emittente ha smesso di aspettare. Campo `cause` obbligatorio |
| `cancelled` | Annullato dall'emittente prima del completion. Causa opzionale |

Ogni transizione di stato include:
- `timestamp`
- `cause` o `reason` (obbligatorio per failed/timed_out/needs_input)
- `updated_by` (peer che ha aggiornato lo stato)

### Handshake iniziale (timeout negoziato)

1. Emittente propone timeout (es. 120s) nel campo `timeout` del messaggio
2. Destinatario risponde con ACK + `timeout_confirmed` o `timeout_proposed` (valore alternativo)
3. Se non c'è accordo, il task va in `cancelled`

### Heartbeat progress

Mentre è in `working`, il destinatario aggiorna il progresso periodicamente.

**Frequenza:** ogni 5-10 secondi, o a ogni step significativo (tool call completata, risultato intermedio).  
**Tolleranza:** se non arrivano heartbeat per > `timeout/2`, l'emittente marca `timed_out`.

```json
{
  "message_id": "msg_abc",
  "status": "working",
  "progress": "web_search: trovati 5 risultati, estraggo articoli",
  "progress_pct": null,
  "has_progress": false,
  "updated_at": "2026-07-14T17:05:00Z"
}
```

- `progress_pct`: numero 0-100 per task con avanzamento lineare (es. "processa 10 file")
- `progress_pct: null` + `has_progress: false`: task esplorativo senza avanzamento misurabile

### Formati messaggio

#### Modalità full (CREATE, UPDATE con cambiamenti strutturali)

Schema completo come in §4.

#### Modalità lightweight (heartbeat, ACK, progress)

Solo campi essenziali + delta:

```json
{
  "message_id": "msg_abc",
  "in_reply_to": "msg_xyz",
  "type": "heartbeat",
  "status": "working",
  "progress": "web_search in corso",
  "progress_pct": null,
  "delta": {}
}
```

---

## 4. Formato Messaggio

### Campi comuni

| Campo | Tipo | Obbligatorio | Descrizione |
|---|---|---|---|
| `hmp_version` | str | sì | Versione protocollo |
| `message_id` | str | sì | UUID univoco |
| `idempotency_key` | str | sì | Chiave per deduplicazione (stessa di message_id per semplicità) |
| `in_reply_to` | str | no | message_id a cui si risponde |
| `from` | str | sì | Peer mittente |
| `to` | str | sì | Peer destinatario |
| `type` | str | sì | `request`, `response`, `heartbeat`, `ack`, `cancel` |
| `status` | str | no | Stato del task |
| `timestamp` | str | sì | ISO 8601 |
| `thread_id` | str | no | Per conversazioni multi-turn |
| `correlation_id` | str | no | Raggruppa subtask di una stessa richiesta madre |
| `routing_path` | [str] | no | Lista dei peer attraversati |
| `timeout` | int | no | Timeout proposto in secondi |
| `timeout_confirmed` | int | no | Timeout confermato dal destinatario |
| `ttl` | str | no | Time-to-live assoluto (ISO 8601, es. `2026-07-14T18:00:00Z`) |
| `payload` | object | no | Contenuto della richiesta/risposta |
| `error` | object | no | Dettaglio errore (per status=failed) |
| `stats` | object | no | Metriche di esecuzione |

### Richiesta (request)

```json
{
  "hmp_version": "1.0",
  "message_id": "msg_abc123",
  "idempotency_key": "msg_abc123",
  "from": "peer84",
  "to": "peer105",
  "type": "request",
  "timestamp": "2026-07-14T17:00:00Z",
  "thread_id": "thr_001",
  "correlation_id": "corr_001",
  "timeout": 120,
  "ttl": "2026-07-14T17:05:00Z",
  "payload": {
    "task_type": "research",
    "instruction": "Trova il prezzo del Milk-V Jupiter 2 nel 2026",
    "scope": "max 3 fonti, 200 parole",
    "output_format": {
      "summary": "str",
      "price_usd": "str",
      "sources": ["str"]
    },
    "context": {
      "language": "it",
      "urgency": "normal"
    }
  }
}
```

### Risposta (response - completed)

```json
{
  "hmp_version": "1.0",
  "message_id": "msg_def456",
  "idempotency_key": "msg_def456",
  "in_reply_to": "msg_abc123",
  "from": "peer105",
  "to": "peer84",
  "type": "response",
  "status": "completed",
  "timestamp": "2026-07-14T17:02:30Z",
  "thread_id": "thr_001",
  "correlation_id": "corr_001",
  "payload": {
    "result": {
      "summary": "Il Milk-V Jupiter 2 costa circa $89 nel 2026...",
      "price_usd": "89",
      "sources": ["https://...", "https://..."]
    }
  },
  "stats": {
    "tools_used": ["web_search", "web_extract"],
    "duration_ms": 145200,
    "tokens_estimated": 4200
  }
}
```

### Errore (response - failed)

```json
{
  "hmp_version": "1.0",
  "message_id": "msg_err789",
  "idempotency_key": "msg_err789",
  "in_reply_to": "msg_abc123",
  "from": "peer105",
  "to": "peer84",
  "type": "response",
  "status": "failed",
  "timestamp": "2026-07-14T17:02:30Z",
  "correlation_id": "corr_001",
  "error": {
    "code": "model_unavailable",
    "message": "Provider restituisce 401 — quota esaurita",
    "cause": "rate_limit_exceeded",
    "retryable": true,
    "retry_after_s": 300
  }
}
```

### ACK (ack)

```json
{
  "hmp_version": "1.0",
  "message_id": "msg_ack001",
  "idempotency_key": "msg_ack001",
  "in_reply_to": "msg_abc123",
  "from": "peer105",
  "to": "peer84",
  "type": "ack",
  "status": "delivered",
  "timestamp": "2026-07-14T17:00:01Z",
  "timeout_confirmed": 120
}
```

### Codici errore standard

| Codice | Descrizione | Retryable |
|---|---|---|
| `model_unavailable` | Provider LLM non raggiungibile o quota esaurita | sì |
| `resource_exhausted` | RAM/CPU del peer insufficiente | sì (dopo delay) |
| `timeout` | Task non completato nel tempo dichiarato | sì |
| `invalid_request` | Messaggio malformato o campo obbligatorio mancante | no |
| `internal_error` | Errore imprevisto nel peer destinatario | sì |
| `not_implemented` | task_type non supportato dal destinatario | no |
| `cancelled` | Annullato dall'emittente | - |

---

## 5. Galateo (Agent Etiquette)

1. **Una richiesta per messaggio.** Se hai 3 domande, fai 3 messaggi separati.
2. **ACK obbligatorio.** Ogni messaggio ricevuto va confermato entro 5s con un ACK. Senza ACK, il mittente re-invia dopo timeout breve (10s).
3. **Idempotenza.** Se ricevi un `message_id` / `idempotency_key` già visto, non rieseguire — restituisci il risultato cache o il vecchio ACK.
4. **Scope minimo.** Il `scope` dice quanto lavoro ci si aspetta. Un agente non dovrebbe fare più del dichiarato.
5. **Timeout realistico.** Se il task può richiedere 3 minuti, dichiara 240s. Il destinatario può rinegoziare nell'ACK.
6. **Output format dichiarato.** L'emittente dice esattamente cosa vuole indietro nel `payload.output_format`. Niente sorprese.
7. **Niente ping-pong.** Se un task finisce in `needs_input`, il destinatario spiega *cosa* manca (`reason`) — non chiede "cosa vuoi fare?".
8. **Auto-limitazione quantitativa.** Ogni peer dichiara nella Agent Card: `rate_limits.max_concurrent_tasks`, `rate_limits.tasks_per_minute`. Se i limiti vengono superati, il peer risponde con `resource_exhausted`.
9. **Priorità.** `payload.context.urgency`: `low` / `normal` / `high`. `high` salta la coda.
10. **Non interrompere.** Un task in `working` non va interrotto a meno che l'emittente non mandi esplicitamente un `type: cancel`.

---

## 6. Discovery — Agent Card

Endpoint: `GET http://<peer>:8642/hmp/agent-card`

```json
{
  "agent": "peer70",
  "role": "coordinator",
  "cluster_role": "primary",
  "version": "hmp-1.0",
  "timezone": "Europe/Rome",
  "skills": ["research", "video_digest", "quest_management"],
  "constraints": {
    "max_concurrent_tasks": 3,
    "max_timeout": 300,
    "supported_types": ["research", "query", "delegate"],
    "availability_window": {
      "always_available": true
    }
  },
  "rate_limits": {
    "max_concurrent_tasks": 3,
    "tasks_per_minute": 10
  },
  "tags": ["coordinator", "rpi", "24-7"],
  "health": "/health",
  "agent_card_ttl": 300
}
```

Peer con risorse limitate:

```json
{
  "agent": "peer105",
  "role": "worker",
  "cluster_role": "observer",
  "version": "hmp-1.0",
  "timezone": "Europe/Rome",
  "skills": ["research", "video_digest"],
  "constraints": {
    "max_concurrent_tasks": 1,
    "max_timeout": 180,
    "supported_types": ["research"],
    "availability_window": {
      "always_available": true,
      "note": "sotto carico potrebbe rispondere lentamente"
    }
  },
  "rate_limits": {
    "max_concurrent_tasks": 1,
    "tasks_per_minute": 3
  },
  "tags": ["worker", "arm", "constrained"],
  "health": "/health",
  "agent_card_ttl": 300
}
```

La Agent Card viene cachata da peer70 con TTL configurabile (`agent_card_ttl`, default 300s).

---

## 7. Migrazione a Cluster (futura, documentata ora)

### Scenario obiettivo

- ≥2 coordinatori (es. peer70 = primary, peer128 = replica)
- DB SQLite su storage condiviso (NFS / sshfs / DRBD)
- WAL mode + busy_timeout = 5000 (coordinazione concorrente)
- Health check: se primary non risponde, replica assume

### Single Point of Failure (accettato per prototipo)

peer70 è attualmente **single point of failure** per lo stato condiviso. Decisione consapevole: la mesh è in fase prototipale, i peer sono in LAN domestica, peer70 è un RPi che gira 24/7.

**Tre strade future:**
1. **Litestream** — replica continua del DB SQLite su storage esterno
2. **Failover su peer128** (quando torna online) — WAL replicato su mount condiviso
3. **Accettare lo SPOF** — documentato e voluto per la fase attuale

Già previsto nell'Agent Card: campo `cluster_role` = `primary` | `replica` | `observer`.

### Procedura di migrazione

1. Fermare tutti i cron HMP su coord-1
2. `sqlite3 agent_messages.db "PRAGMA wal_checkpoint(TRUNCATE);"`
3. Copiare il DB sul mount condiviso
4. Puntare `hmp_config.yaml` su `db_path: /mnt/shared/agent_messages.db`
5. Avviare coord-2 (replica) con stesso path e `cluster_role: replica`
6. Verificare che entrambi leggano/scrivano
7. Riavviare cron su coord-1 (ora punta al path condiviso)
8. Health check periodico: se coord-1 non risponde, coord-2 passa a `cluster_role: primary`

### Limitazioni note

- SQLite non è PostgreSQL. Per 4 peer in LAN va benissimo.
- WAL mode permette 1 scrittore + N lettori. Se due coordinatori scrivono simultaneamente, SQLite risolve col busy_timeout.
- Se un giorno il traffico cresce, si migra a LiteFS o Postgres — la struttura messaggi non cambia, solo il backend.

---

## 8. Implementazione

### Modulo Python: `hmp.py` (~400 righe)

```
hmp/
├── __init__.py          # esporta HMPBus, HMPServer, HMPClient
├── bus.py               # HMPBus — interfaccia SQLite
├── models.py            # dataclass / dict schema
├── server.py            # HMPServer — endpoint HTTP su :8642
├── client.py            # HMPClient — utility per peer non-coordinatori
├── errors.py            # codici errore standard
└── config.py            # Config da file YAML
```

### Dipendenze

- Python 3.11+ stdlib (sqlite3, json, http.server, threading, uuid, datetime)
- Zero dipendenze esterne. Zero pip install.

### API endpoints (su :8642)

| Endpoint | Metodo | Descrizione |
|---|---|---|
| `/hmp/send` | POST | Invia un messaggio al bus |
| `/hmp/poll/{message_id}` | GET | Leggi stato e progress di un messaggio |
| `/hmp/agent-card` | GET | Restituisce la Agent Card del peer |
| `/hmp/discover` | GET | Lista di tutti i peer conosciuti e le loro Agent Card |
| `/hmp/cancel/{message_id}` | POST | Annulla un task pendente |

### Cron su peer70

| Cron | Intervallo | Ruolo |
|---|---|---|
| `hmp-message-router` | 30s | Consegna messaggi pending → queued → delivered |
| `hmp-watchdog` | 2m | Heartbeat monitoring, segnala peer non reattivi |
| `hmp-dream-engine` | 02:00 CEST | Compatta SQLite, archivia task vecchi |

**Tutti i cron usano `no_agent=True`** — script Python puri senza LLM.

### Schema SQLite

```sql
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT UNIQUE NOT NULL,
    idempotency_key TEXT NOT NULL,
    in_reply_to TEXT,
    from_peer TEXT NOT NULL,
    to_peer TEXT NOT NULL,
    type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    thread_id TEXT,
    correlation_id TEXT,
    routing_path TEXT,
    timeout INTEGER,
    timeout_confirmed INTEGER,
    ttl TEXT,
    payload TEXT,
    error TEXT,
    stats TEXT,
    progress TEXT,
    progress_pct REAL,
    has_progress INTEGER DEFAULT 0,
    cause TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    delivered_at TEXT,
    completed_at TEXT
);

CREATE INDEX idx_messages_to_peer_status ON messages(to_peer, status);
CREATE INDEX idx_messages_correlation ON messages(correlation_id);
CREATE INDEX idx_messages_thread ON messages(thread_id);
```

---

## 9. Integrazione con sistema esistente

### Relazione con i tool MCP esistenti

- `call_peer` → sostituito da messaggi HMP request/response. Resta per debug.
- `start_peer_run` → sostituito da messaggi async con heartbeat. Resta per task non-HMP.
- `peer_health` → assorbito in `/hmp/agent-card`
- `peer_capabilities` → assorbito in Agent Card

### Relazione con workflow esistenti

- **Dual-peer autonomous loop:** stessi step, ma chiamate rimpiazzate da messaggi HMP strutturati
- **Experience exchange:** self-report → messaggio HMP `task_type: "experience_report"`
- **Coordinator handover:** procedura appoggiata su HMP per migrazione cron/DB