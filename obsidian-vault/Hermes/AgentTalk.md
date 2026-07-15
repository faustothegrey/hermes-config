# AgentTalk

Sistema MCP multi-agente: orchestratore + worker disaccoppiati via WebSocket con wire contract hashato.

## Architettura

**Due repo separati, nessuna dipendenza diretta tra i due codici:**

1. **AgentTalk** (`~/Software/AgentTalk/`) — Orchestratore MCP
2. **agentalk-mcp-client** (`~/Software/agentalk-mcp-client/`) — Worker MCP standalone

La comunicazione avviene tramite **wire contract** (SHA-256), non codice condiviso.

---

## AgentTalk — Orchestratore

**Path:** `~/Software/AgentTalk/`
**Stack:** TypeScript 6.x, monorepo npm (workspaces), Vitest, `@modelcontextprotocol/sdk`
**Canone regole:** `AGENT.md` (58K) — **file singolo**, `AGENTS.md` e `CLAUDE.md` sono symlink. Editare solo `AGENT.md`.

### Struttura workspaces

```
apps/
├── orchestrator/    — Backend MCP Server, stato conversazioni, orchestrazione team
└── web/             — Frontend
packages/
├── contracts/               — Wire contract (tipi + protocol-payloads + wire-contract.json)
├── integration-google-drive/
├── llm-client/              — API client, chat-session, completer, MCP chat completer
├── mcp-exec-server/         — MCP execution server
├── mcp-transport/           — MCP transport layer
├── observability/           — Logging/metrics
├── runtime-core/            — Agenti, conversazioni, protocollo, registry, condivisione
└── runtime-scenarios/       — Scenari + scheduler
```

### Sistema ruoli e session primers

Multi-agente strutturato con ruoli separati:

| Ruolo | Gate |
|-------|------|
| **Planner** | Prepara il piano |
| **Plan Reviewer** | Gate 1 — approva il piano |
| **Implementer** | Costruisce |
| **Implementation Reviewer** | Gate 2 — verifica/refuta ogni delivery |
| **Task-end Reviewer** | Gate 3 — closure sweep + merge |
| **Tester** | Esegue i test |
| **Architect** | PO-assigned, epic inception (nessun primer cold-start) |

**Meccanismo primer a chiave condivisa**: ogni ruolo ha un file `design/session-primers/<ruolo>-primer.md` con header `key:`. L'agente lo consuma una volta e lo segna nel suo private key store (fuori dal repo) — così restart non ri-triggerano il cold-start stop.

**Regole:**
- Plan Reviewer ≠ Planner, Implementation Reviewer ≠ Implementer (nessun self-review)
- Resource-scarcity fallback: un agente può coprire più ruoli, ma dichiara sempre ogni ruolo che ricopre
- Ogni sessione inizia con: handshake primer → poll usage meter (`node scripts/usage.mjs`) → skim lessons file (`design/lessons/<agente>-lessons.md`) → dichiarazione ruolo/i

### Script principali

- `scripts/supervisor.mjs` — Dev supervisor process
- `scripts/restart-supervisor.mjs` — Riavvio supervisor
- `scripts/usage.mjs` — Parser usage meter (chiama `/usage` + `/tokens` su `127.0.0.1:9899`)
- `scripts/validate-backlog.mjs` — Validatore backlog
- `scripts/arbiter-shadow-judge.mjs` — Shadow judging per arbiter
- `scripts/arbiter-corpus-audit.mjs` — Corpus audit
- `scripts/arbiter-generate-corpus-append.mjs` — Generazione corpus
- `scripts/arbiter-score-results.mjs` — Score risultati
- `scripts/spike-ws-server.mjs` — WebSocket spike server
- `scripts/test-*.mjs` — Vari test live (MCP gate, API team, cross-provider, ecc.)

### Comandi npm

| Comando | Cosa fa |
|---------|---------|
| `npm run build` | `tsc -b && npm run build --workspace @agenttalk/web` |
| `npm run test` | Test contracts + vitest |
| `npm run dev` | Backend + frontend concurrently |
| `npm run dev:supervised` | Con supervisor process |
| `npm run backend` | Solo orchestrator |
| `npm run frontend` | Solo web |
| `npm run scenario` | Scenario runner (workspace orchestrator) |

### Milestone

Codice milestone corrente nel ledger `design/milestone*-implementation.md`. AGENT.md dichiara:
- Preserva comportamento esistente per default
- Nessun cambio comportamento senza conferma esplicita
- Test come contratti di comportamento
- Edit minimi e mirati con regression test

---

## agentalk-mcp-client — Worker MCP

**Path:** `~/Software/agentalk-mcp-client/`
**Stack:** JavaScript (ESM), `node-pty`, `strip-ansi`, `ws`, Vitest
**Descrizione:** Worker attach-mode che si connette all'orchestratore AgentTalk via WebSocket persistente

### Componenti chiave

| File | Ruolo |
|------|-------|
| `bridge.mjs` | Connessione WebSocket all'orchestratore |
| `llm-agent.mjs` | Entry point LLM agent (binario: `llm-agent`) |
| `codex-pty.mjs` | PTY driver per Codex |
| `claude-pty.mjs` | PTY driver per Claude |
| `gemini-pty.mjs` | PTY driver per Gemini (via Antigravity) |
| `wire-contract.json` | Copia locale del wire contract (hash verificato) |
| `attach-skill.md` | Skill per l'agente in attach mode — ciclo: await_turn → esegui → result |

### Lib

| File | Ruolo |
|------|-------|
| `lib/protocol.mjs` | Protocollo MCP |
| `lib/mcp-client.mjs` | Client MCP base |
| `lib/request-id.mjs` | Gestione request ID |
| `lib/provider-runtime.mjs` | Runtime per provider LLM |
| `lib/executor-runtime.mjs` | Runtime executor |

### Wire Contract

- Fonte di verità: `AgentTalk/packages/contracts/wire-contract.json`
- Copia locale: `agentalk-mcp-client/wire-contract.json`
- Sync: `npm run sync-contract` (legge da `../AgentTalk/packages/contracts/wire-contract.json`; override con `AGENTTALK_CONTRACT_PATH`)
- Verifica: SHA-256 handshake all'initialize MCP. Hash mismatch → connessione rifiutata con `1008 Policy Violation`
- **One-way import guard**: niente dipendenze dirette dal client all'orchestratore (enforzato da lint/build)

### Resilienza

- Reconnect esponenziale su perdita connessione WebSocket
- Polling continuo del tool `await_turn` dall'orchestratore

### Comandi npm

| Comando | Cosa fa |
|---------|---------|
| `npm run build` | Lint + verify-contract + test |
| `npm run test` | Vitest |
| `npm run lint` | ESLint |
| `npm run verify-contract` | Verifica hash |
| `npm run sync-contract` | Sync da AgentTalk |

---

## Flusso di comunicazione

```
Orchestratore (AgentTalk)
    │  MCP Server WebSocket
    │  wire contract SHA-256 handshake
    ▼
Worker (agentalk-mcp-client)
    │  bridge.mjs ←→ protocol.mjs
    │  await_turn polling loop
    ▼
PTY Driver (codex-pty / claude-pty / gemini-pty)
    │  node-pty
    ▼
Provider LLM (Codex CLI / Claude Code / Gemini)
```

---

## Collegamenti

- [[Peer Mesh]] — possibile integrazione futura HMP ↔ MCP
- [[External AI CLIs]] — Claude Code, Codex CLI usati anche dai PTY driver