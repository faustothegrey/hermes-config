# AI Quota Monitoring

Sistema di monitoraggio delle quote di utilizzo per AI CLI (Claude Code, Codex CLI, Antigravity CLI, OpenRouter) via API HTTP + dashboard web.

**Path:** `~/Software/scripts-ai/quota-monitoring/`
**Stack:** Python, HTML/JS, **tmux 3.2a** (per scrape interattivo), launchd (macOS)
**Porta:** `127.0.0.1:9899`

---

## Architettura

```
api.py (server HTTP, background loop su thread separato)
  │  refresha ogni ~2 min (tokens) e ogni ~10 min (usage)
  │
  ├─ GET /tokens  → Claude transcript token totals (leggero, no tmux)
  ├─ GET /usage   → Usage % per Claude/Codex/Antigravity (tmux scrape) + OpenRouter credits (API REST)
  │
  ├─ dashboard.html  → frontend HTML che polla /tokens e /usage ogni 30s
  └─ telemetry.py    → CLI che stampa la telemetria in umano (consuma /usage)
```

## Componenti

| File | Ruolo |
|------|-------|
| `api.py` | Server HTTP su :9899. Background thread fetch loop: tokens ogni ciclo (~2min), usage ogni 5 cicli (~10min). Cache locking thread-safe. |
| `dashboard.html` | Dashboard web stile terminal (monospace, verde su nero). Polla `/tokens` e `/usage` ogni 30s con fetch() + JSON.stringify. |
| `telemetry.py` | CLI: stampa usage Claude/Codex/Antigravity/OpenRouter in formato umano da `/usage`. |
| `lib.py` | Re-export di `ai_quota_lib` per retrocompatibilità. |
| `scripts/claude` | CLI standalone — stampa quota Claude (session + weekly + token ultimi 30gg). `--json` per output strutturato. |
| `scripts/codex` | CLI standalone — stampa quota Codex da `/status` interattivo (5h + weekly). `--json`. |
| `scripts/antigravity` | CLI standalone — stampa quota Antigravity da `/usage` (5h model-quota window). `--json`. |
| `com.fausto.claude-api.plist` | launchd plist per macOS — avvio automatico all'login con KeepAlive. Log su `~/.hermes/logs/quota-api.log`. |

## Provider monitorati

### Claude Code
- **Fonte:** `claude /usage` (tmux scrape via `claude_interactive_usage`)
- **Metriche:** sessione corrente (% used, reset) + settimana corrente tutti i modelli (% used, reset)
- **Tokens:** `claude_usage_from_transcripts` (legge transcript JSON in `~/.claude/`, ultimi 30gg)

### Codex CLI
- **Fonte:** `codex /status` (tmux scrape via `codex_interactive_status`)
- **Metriche:** finestra 5h (% used/left, reset) + finestra settimanale (% used/left, reset)

### Antigravity CLI
- **Fonte:** `agy /usage` (tmux scrape via `antigravity_interactive_usage`)
- **Metriche:** finestra 5h, per-modello (% used/left, reset), modello corrente, lowest_left_percent

### OpenRouter
- **Fonte:** API REST `https://openrouter.ai/api/v1/credits` con `OPENROUTER_API_KEY` dall'env shell
- **Metriche:** total_credits, total_usage, credits_remaining, used_percent

## Cache e refresh

```
/tokens → refresh ogni ~2 min (sempre, tick 1,2,3...)
/usage  → refresh ogni ~10 min (tick 1,5,10,15...) — tmux scrape pesante
```

Ogni richiesta HTTP legge dalla cache — nessuna richiesta blocca sul fetch.

## Aggregazione

`compute_aggregate()` calcola il `max_used_percent` tra tutti i provider e la lista dei provider attivi, esposto in `/usage` sotto `aggregate`.

## Deployment

- **macOS:** via launchd (plist), run at load, keep alive, log in `~/.hermes/logs/quota-api.log`
- **Linux (peer84):** via systemd `quota-monitoring.service`, enabled, active (running). Log in `~/.hermes/logs/quota-api.log`.
- **API Keys:** caricate da `/etc/quota-service.env` (systemd EnvironmentFile, chmod 600) e da `~/.env` (sourced da `.profile` per login shell).
- **Dipendenza esterna:** `ai_quota_lib` — installata su peer84 in `~/Software/scripts-ai/ai-quota-lib/` (package Python) e su peer128 (Mac).
- **Note:** i fetch "usage" (tmux scrape) funzionano solo quando Claude/Codex/Antigravity hanno sessioni tmux attive. I token fetch invece funzionano sempre (legge transcript JSON).

## Collegamenti

- [[AgentTalk]] — `node scripts/usage.mjs` consuma la stessa API su :9899
- [[External AI CLIs]] — strumenti monitorati
- [[AI CLI Quotas]] — note correlate