---
name: hermes-memory-architecture
description: "5-layer memory architecture aligned across peer mesh: HOT (built-in), WARM (Holographic HRR+SQLite), COLD (session_search), PROCEDURAL (skills), VAULT/KB (Obsidian). Activation, verification, terminology, and rollback."
version: 1.0.0
author: Hermes Agent N56VV + peer128
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [memory, holographic, peer-mesh, architecture, 5-layer]
---

# Hermes Memory Architecture — 5-Layer Model

Canonical memory architecture adopted across the peer mesh (N56VV + peer128 MBP Fausto), inspired by cognitive psychology and the AI agent community standards.

## 5 Layers

| Layer | Name | Implementation | Contents | Access Pattern |
|-------|------|---------------|----------|---------------|
| **HOT** | Prompt memory | Built-in: MEMORY.md + USER.md | Durable facts, preferences, environment | Injected every session, always in context |
| **WARM** | Associative memory | Holographic provider (HRR + SQLite) | Micro-facts, corrections, behavioral details | Recall on-demand at turn start, <1ms |
| **COLD** | Episodic memory | session_search (state.db FTS5) | Past conversations | Explicit query only |
| **PROCEDURAL** | Skill memory | ~/.hermes/skills/ | Reusable workflows, "how-to" | Loaded via skill_view on demand |
| **VAULT/KB** | Knowledge base | Obsidian vault | Project docs, research notes | Search on-demand, never preloaded |

Cognitive metaphor:
```
HOT   = what's in your mind right now      (cognitive RAM)
WARM  = what you recall if prompted         (fast cache)
COLD  = what you know happened but must     (archive)
        dig up
VAULT = your reference library              (structured knowledge)
```

## Holographic Provider Details

- **Technology**: HRR (Holographic Reduced Representations) — algebraic compression, not semantic embeddings
- **Storage**: Local SQLite, no external services
- **Trust scoring**: Facts gain/lose weight based on confirmation/contradiction over time — self-correcting
- **Latency**: <1ms retrieval
- **Resources**: <5 MB RAM, negligible CPU, zero network

### Tools Exposed

- `fact_store(action='add', content='...', category, entities, tags)` — save a fact
- `fact_store(action='search', query='...')` — keyword search
- `fact_store(action='probe', entity='...')` — all facts about an entity
- `fact_store(action='reason', entities=['A','B'])` — facts connecting multiple entities
- `fact_store(action='contradict')` — hygiene: find conflicting facts
- `fact_store(action='update'/'remove'/'list')` — CRUD
- `fact_feedback(action='helpful'/'unhelpful', fact_id=N)` — train trust scoring

### Auto-extract

**Off by default.** Explicit control over what enters warm memory is preferred.

## Activation

```bash
# Check prerequisites
hermes memory status
python3 -c "import numpy; print('numpy:', numpy.__version__)"

# Activate
hermes config set memory.provider holographic

# Verify
hermes memory status
# Should show: holographic (local) ← active

# New tools available after /reset or new session
```

## Rollback

```bash
hermes memory off
# Back to built-in only, zero data loss
```

## Known Issues

### Bug #17350 — Silent degradation when numpy missing

When numpy is not installed, Holographic silently falls back to FTS5-only:
- HRR disabled, no warning logged
- `probe()`, `related()`, `reason()`, `contradict()` all fall back to basic `search()`
- `hermes doctor` does not detect it

**Mitigation**: Always verify numpy is installed before enabling. Run:
```bash
python3 -c "import numpy; print('OK')"
```

## When to use WARM vs HOT

Decision heuristic — if it's about a SPECIFIC system, host, peer, or entity, it goes in WARM (fact_store) so it gets recalled on-demand when operating on that entity. If it's a CROSS-CUTTING preference or fact that applies regardless of context, it goes in HOT.

**WARM (fact_store) — entity-scoped operational data:**
- Per-host resource specs (RAM, CPU, disk constraints)
- Per-peer quirks, config issues, workarounds
- Per-project tool preferences
- Anything you want recalled automatically when the entity appears in context

**HOT (memory tool) — cross-cutting durable facts:**
- User identity, language, communication style
- Global environment facts (OS, installed tools, project structure)
- Cross-cutting conventions that apply everywhere
- Stable user preferences not tied to a specific host/project

User explicitly prefers this pattern for peer/entity operational data: use WARM, not HOT.

## Operational Workflow: Look Before You Leap 🛑

**Fundamental principle:** Before executing any tool call, API call, or live investigation on an entity (peer, host, project), check existing memory sources FIRST in this order:

| Order | Layer | Tool / Location | Rationale |
|-------|-------|----------------|-----------|
| 1 | HOT | `memory` tool (injected) | Always in context — instant |
| 2 | WARM | `fact_store(action='probe', entity='X')` or `reason` | <1ms, auto-recalled for tagged entities |
| 3 | COLD | `session_search(query='...')` | Past conversations about the topic |
| 4 | VAULT | `search_files` on `~/Documents/Obsidian Vault/` | Project docs, peer specs, research notes |
| 5 | PROCEDURAL | `skill_view(name='...')` | Load relevant skill if task type matches |

**Decision tree:**
```
Information about entity X needed?
  ├─ Found in HOT/WARM/COLD/VAULT? → Use it. Done.
  ├─ Found but clearly outdated? → Ask user for confirmation, then use or refresh.
  └─ Not found anywhere? → NOW probe the live system.
```

**Anti-pattern (avoid):** Jumping straight to API calls, SSH probes, or terminal commands when the answer already lives in the vault or a previous session. This wastes tokens, time, and user patience — and undermines the purpose of the multi-layer memory architecture.

**Example (from real session):** User asks about peer105 specs. Instead of probing via API (which failed 3 times because the model was broken), the answer was already in `~/Documents/Obsidian Vault/Hermes/Peer105 YouTube.md` lines 24-30. A 2-second vault search would have found it.

Full case study: `references/case-study-peer105-probe-failure.md`

## Golden Rules

- Hot memory: curated, compact, durable facts only — cross-cutting, not entity-scoped
- Warm memory: entity-scoped operational facts, self-correcting via trust scoring, recalled on-demand when operating on tagged entities
- Cold memory: past transcripts, never preloaded
- Procedural: loaded when task matches, not always in context
- Vault/KB: NEVER indexed by warm memory, only explicit search
- Only ONE external memory provider at a time

## Pitfalls

- Jumping to live probes before exhausting memory layers — the most common and costly mistake (see Operational Workflow above)
