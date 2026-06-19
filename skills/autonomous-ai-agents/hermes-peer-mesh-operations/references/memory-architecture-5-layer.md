# Shared Memory Architecture (5-Layer Model)

Adopted 2026-06-19 across peer mesh (peer84/N56VV + peer128/MBP Fausto).
Aligned with community AI agent nomenclature inspired by cognitive psychology.

## Layer Map

| Layer | Term | Implementation | Contents | Access Pattern |
|-------|------|----------------|----------|----------------|
| **Hot** | Prompt memory | Built-in: MEMORY.md + USER.md | Durable facts, preferences, environment | Injected every session, frozen |
| **Warm** | Associative memory | Holographic provider (HRR + SQLite) | Micro-facts, corrections, behavioral details | Recall on-demand, <1ms, trust scoring |
| **Cold** | Episodic memory | session_search (state.db FTS5) | Past conversations | On explicit request only |
| **Procedural** | Skill memory | `~/.hermes/skills/` | Reusable workflows, "how to" | Loaded via skill_view on demand |
| **Vault/KB** | Knowledge base | Obsidian vault | Project docs, research notes | Search on-demand, never preloaded |

## Cognitive Metaphor

```
HOT   = what's in your mind right now       (cognitive RAM)
WARM  = what you recall if prompted          (fast cache)
COLD  = what you know you did but must dig   (archive)
VAULT = your reference library               (structured knowledge)
```

## Synonyms

- "vault" → Obsidian vault
- "KB" (case-insensitive) → Knowledge Base = Obsidian vault

## Architecture Diagram

```
CURRENT SESSION
├── Hot memory (built-in)    → always in context, curated, compact
├── Warm memory (Holographic) → recall on-demand, self-correcting (trust scoring)
├── Cold memory (session_search) → FTS5 queries on request
├── Procedural (skills)       → loaded when task matches
└── Vault/KB (Obsidian)       → search on-demand, never indexed by warm memory
```

## Holographic Provider Details

- **Engine**: HRR (Holographic Reduced Representations) — algebraic, not semantic
- **Storage**: Local SQLite, zero external dependencies
- **Trust scoring**: Facts gain/lose weight based on confirmation/contradiction over time
- **Tools**: `fact_store` (CRUD + probe/reason/contradict/search), `fact_feedback` (helpful/unhelpful)
- **Auto-extract**: OFF by default (explicit control preferred)

## Activation (per peer)

```bash
hermes memory setup          # interactive → select "holographic"
# or:
hermes config set memory.provider holographic
hermes memory status         # verify: "holographic (local) ← active"
```

Revert: `hermes memory off`

## Pitfall: Silent FTS5 Degradation (Hermes issue #17350)

When `numpy` is NOT installed, the holographic plugin silently disables all HRR-based
semantic search and falls back to FTS5 keyword matching — with NO warning, NO error,
and `hermes doctor` does NOT detect it.

**Symptoms of degraded mode:**
- `retrieval_count` stays at 0 for all facts
- `probe()`, `related()`, `reason()` silently fall back to `search()` (FTS5 AND semantics)
- `contradict()` returns empty list
- "Cold start" amnesia at beginning of every session

**Pre-check before activating:**
```bash
python3 -c "import numpy; print('numpy:', numpy.__version__)"
```

If numpy is present, HRR is active and the plugin works at full capability.
If missing: `pip install numpy`, then restart the session.
