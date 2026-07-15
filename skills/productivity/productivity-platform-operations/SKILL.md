---
name: productivity-platform-operations
description: "Productivity integrations: Google Workspace, Airtable, Notion, PDFs/OCR, PowerPoint, maps, email, Obsidian, and Teams pipelines."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [productivity, google-workspace, airtable, notion, pdf, powerpoint, email, notes, teams]
---

# Productivity Platform Operations

Use this class-level skill for user productivity systems: Google Workspace, Airtable, Notion, PDFs/OCR, PowerPoint, maps/geocoding, email, Obsidian vaults, and Teams meeting pipelines.

## Platform selection

| Task | Preferred workflow |
|---|---|
| Gmail/Calendar/Drive/Docs/Sheets | Google Workspace CLI/API workflow |
| IMAP/SMTP email | Himalaya CLI workflow |
| Structured records/tables | Airtable REST API |
| Knowledge pages/databases | Notion CLI/API |
| Local markdown knowledge base | Obsidian filesystem workflow |
| PDF/scanned document extraction | OCR/document extraction tools |
| PDF typo/title edits | nano-pdf |
| PPTX create/read/edit | PowerPoint tooling |
| Geocoding/routes/POIs/time zones | Maps/OpenStreetMap/OSRM workflow |
| Teams transcript/action summary ops | Teams meeting pipeline CLI |

## General rules

- Resolve credentials and target workspace/account before mutating anything.
- Prefer read-only discovery before writes.
- Treat sending email, modifying calendars, editing databases, and posting pages as external side effects.
- Verify by reading back the created/modified resource when possible.

## Google Workspace

Use for Gmail, Calendar, Drive, Docs, and Sheets. Prefer the configured Google Workspace CLI or Python client. Confirm account, document IDs, sheet names, calendar, and sharing settings before changes.

For Gmail access checks, do not stop at “account/token file exists”. Verify usable OAuth with a real Gmail API call. Check `~/.hermes/google_token.json` metadata safely, try token refresh, then call `gmail.users().getProfile(userId='me')` or list one inbox message. If refresh returns `invalid_grant` / `Token has been expired or revoked`, report that OAuth was configured but must be re-authorized. See `references/google-gmail-oauth-diagnostics.md`.

## Email via Himalaya

Use Himalaya for terminal IMAP/SMTP: search/read mail, draft/send messages, and manage folders. Confirm recipients and final body before sending sensitive mail.

### Basic workflow

List configured accounts:
```
himalaya account list
```

Send a new email (template workflow — preferred):
```
himalaya template write \
  -H "To:user@example.com" \
  -H "Subject:Your subject" \
  "email body text here" | himalaya template send
```

Use `-a <account>` with both commands to target a non-default account.

Send a raw .eml message (alternative — headers must be fully specified):
```
himalaya message send << RAW
From: Name <sender@example.com>
To: recipient@example.com
Subject: Your subject

email body
RAW
```

Search and read mail:
```
himalaya envelope list -f INBOX
himalaya message read <ENVELOPE_ID>
```

### Account config

Config lives at `~/.config/himalaya/config.toml`. Each account block has email, display-name, IMAP backend, and SMTP backend. Passwords go via an auth script (e.g. `~/.config/himalaya/virgilio-password`).

```
[accounts.virgilio]
email = "user@virgilio.it"
display-name = "Name"
default = true

backend.type = "imap"
backend.host = "imap.virgilio.it"
...

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.virgilio.it"
message.send.backend.port = 465
message.send.backend.encryption.type = "tls"
...

folder.aliases.sent = "Posta Inviata"
```

### Binaries and PATH

Himalaya binary at `~/.local/bin/himalaya`. When called from execute_code subprocess, the sandbox PATH includes this directory, but for safety use the full path: `/home/fausto/.local/bin/himalaya`.

### Virgilio SMTP pitfalls

- **451 "too many invalid recipients"**: server-side transient error from smtp.virgilio.it. Authenticates fine, template is correct, but Virgilio rejects delivery. This affects ALL recipients, even @virgilio.it addresses. Resolution: retry later; if it persists check webmail for account blocks.
- The account needs IMAP + SMTP auth via separate password prompts (same cmd). Both authenticate independently.
- Folder aliases: `folder.aliases.sent = "Posta Inviata"` (Italian, not "Sent").

### Verification

- After any mutation (send, move, delete), read back or list the affected folder.
- For send failures, distinguish client-side (wrong command, bad headers) from server-side (451, 550, etc.). Check the himalaya debug/trace output for the SMTP server's response code.

### Reference

Session-specific detail (Virgilio 451 reproduction, command syntax trials, password auth, folder aliases) is in `references/himalaya-email.md` under this skill.

## Airtable and Notion

Use Airtable for structured record CRUD and filtering. Use Notion for pages, databases, block content, markdown import/export, and Notion Workers when available.

## Documents: PDF, OCR, PowerPoint

- For remote PDFs, try web extraction first.
- For scanned PDFs/images, use OCR/document extraction.
- For PDF text edits, use nano-pdf and verify the edited page.
- For PPTX, use PowerPoint-specific tooling for slides, notes, layouts, comments, and thumbnails.

## Maps/location intelligence

Use open data sources for geocoding, nearby POIs, routes, distances, and time zones. When user sends a location pin, preserve lat/lon precision and clarify radius/category only if not inferable.

## Obsidian

Use filesystem-first markdown operations. The vault is at `~/Documents/Obsidian Vault/` (path: `~/Documents/Obsidian Vault/Hermes/` for Hermes-specific notes). Resolve the vault path from `OBSIDIAN_VAULT_PATH` or this default. Avoid passing unexpanded shell variables to file tools.

### Vault structure

```
~/Documents/Obsidian Vault/
├── Hermes/
│   ├── Overview.md              ← Indice principale, linka tutte le note Hermes
│   ├── AgentTalk.md             ← Progetti/tecnologie
│   ├── External AI CLIs.md      ← Strumenti esterni
│   ├── Peer Mesh.md             ← Infrastruttura mesh
│   ├── Quests/                  ← Ricerche a lungo termine (quest-system skill)
│   │   └── <quest-name>.md
│   ├── <project-or-topic>.md    ← Altre note operative
│   └── ...
├── System/                      ← Sistema e configurazione
│   ├── Email.md
│   ├── Scheduled Restarts.md
│   └── ...
└── Projects/                    ← Progetti esterni (non Hermes)
    └── ScienceClick2.md
```

### Conventions

- **Wiki-link** tutte le note collegate: `[[AgentTalk]]`, `[[Peer Mesh]]`, `[[../System/Email]]`
- **Lingua**: italiano o inglese, a seconda del contesto (l'utente alterna)
- **Tono**: operativo, tecnico, concreto — niente fronzoli
- **Struttura di una nota progetto**: header → descrizione → architettura → componenti chiave → comandi → collegamenti
- **Tabella per comandi npm/CLI**: pipe separator con `| Comando | Cosa fa |` per leggibilità
- **Diagrammi ASCII** per flussi di comunicazione quando serve chiarezza architetturale

### Workflow: documentare un progetto nuovo

Quando l'utente chiede di esplorare e documentare progetti (es. "metti su Obsidian"):

1. **Scopri la struttura**: lista file, leggi package.json/README, identifica sottodirectory e packages
2. **Leggi i file chiave**: entry point, README, AGENT.md/AGENTS.md, attach-skill.md
3. **Salva in memoria**: riassunto conciso in ~400 caratteri (strumento memory)
4. **Crea nota Obsidian** in `Hermes/<ProjectName>.md`:
   - Sezione architettura con componenti e relazioni
   - Struttura directory (tree o lista)
   - Tabella comandi principali
   - Diagramma ASCII del flusso di comunicazione
   - Blocco collegamenti con wikilink alle note correlate
5. **Linka da Overview.md**: aggiungi `[[<ProjectName>]]` alla lista in `Hermes/Overview.md`
6. **Verifica**: rileggi la nota per confermare che sia completa e ben formattata
7. **Verifica dipendenze reali**: se la nota menziona tool/binari/dipendenze (es. "dipende da tmux"), controlla con un comando shell che siano effettivamente installati nel sistema corrente. Aggiorna la nota col risultato.

### Quest tracking (vds. quest-system skill)

Le quest (ricerche a lungo termine) usano la stessa struttura ma con formato e cron di advancement dedicati, documentati nella skill `quest-system`.

### Pitfalls

- **Memoria Hermes piena**: quando `memory(action='add')` fallisce con errore capacity, consolida prima: unisci voci sovrapposte con `replace`, rimuovi obsolete con `remove`. Poi riprova. Capacità 2,200 caratteri — tieni ogni voce a ~300-400 caratteri. Voci sullo stesso sistema (es. AgentTalk + agentalk-mcp-client) vanno fuse in una sola.

## Teams meeting pipeline

Operate via `hermes teams-pipeline` subcommands for meeting summaries, transcripts, recordings, action items, Graph subscriptions, job replay, and pipeline status.
