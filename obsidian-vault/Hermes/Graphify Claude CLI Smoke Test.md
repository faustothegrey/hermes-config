# Graphify Claude CLI Smoke Test

Data: 2026-06-07

## Punto di ripartenza

Abbiamo verificato che Graphify può usare direttamente la Claude Code CLI locale per l'estrazione semantica, senza API key LLM esterne:

```bash
graphify extract <path> --backend claude-cli
```

Questo è utile per corpus Markdown/knowledge base e per corpus misti codice + docs.

## Stato ambiente

- Claude Code CLI presente: `claude 2.1.154 (Claude Code)`
- Graphify non era nel PATH globale durante il test, ma era disponibile nella venv temporanea:
  - `/tmp/graphify-venv`
- Comando quota usato:
  - `/home/fausto/bin/ai-cli-quotas`
- Claude Code usage al momento del test: circa 16% settimana corrente, reset Jun 10 9am Europe/Rome.

## Smoke test mini KB Markdown

Corpus temporaneo:

```text
/tmp/graphify-kb-smoke
```

Comando riuscito:

```bash
. /tmp/graphify-venv/bin/activate
graphify extract /tmp/graphify-kb-smoke \
  --backend claude-cli \
  --no-cluster \
  --out /tmp/graphify-kb-cli-out \
  --token-budget 2000 \
  --max-concurrency 1
```

Risultato:

```text
found 0 code, 3 docs, 0 papers, 0 images
semantic extraction on 3 files via claude-cli
wrote graph.json — 10 nodes, 14 edges
```

Nodi estratti includevano:

- ScienceClick2
- Scene Editor
- Drag-and-Drop Labels
- Target Zones
- Spectator Mode
- Classroom Demonstrations
- Didattica Interattiva
- Labeling Diagrams
- Checking Answers
- Educational Activities

## Smoke test ScienceClick2 parziale

Micro-corpus temporaneo:

```text
/tmp/scienceclick2-graphify-cli-smoke
```

File copiati da `/home/fausto/Software/ScienceClick2`:

- `PROJECT.md`
- `README.md`
- `src/components/editor/HeaderBar.tsx`
- `src/components/editor/Canvas.tsx`
- `src/app/scenes/[id]/spectator/page.tsx`

Comando riuscito:

```bash
. /tmp/graphify-venv/bin/activate
graphify extract /tmp/scienceclick2-graphify-cli-smoke \
  --backend claude-cli \
  --no-cluster \
  --out /tmp/scienceclick2-graphify-cli-smoke-out \
  --token-budget 2500 \
  --max-concurrency 1
```

Risultato:

```text
found 3 code, 2 docs, 0 papers, 0 images
AST extraction on 3 code files
semantic extraction on 2 files via claude-cli
wrote graph.json — 30 nodes, 48 edges
19,424 tokens in / 7,436 out, est. cost $0.0000
```

Output principale:

```text
/tmp/scienceclick2-graphify-cli-smoke-out/graphify-out/graph.json
```

Nodi rilevanti dal codice:

- `SpectatorPage()`
- `Canvas()`
- `DropZone()`
- `HeaderBar()`
- `getTeamColors()`
- `MatchStatus`
- `CanvasProps`
- `HeaderBarProps`

Nodi rilevanti dalla documentazione:

- ScienceClick Application
- Next.js 16
- React 19
- TypeScript
- Tailwind CSS
- @dnd-kit/core
- Next.js API Routes
- File-system Storage
- Scenes
- catalog.json Index
- sync-skills.py Script
- Skills Directory

Relazioni viste:

- `calls`
- `contains`
- `implements`
- `imports_from`
- `references`
- `conceptually_related_to`
- `semantically_similar_to`
- `shares_data_with`

## Query testata

```bash
. /tmp/graphify-venv/bin/activate
cd /tmp/scienceclick2-graphify-cli-smoke-out
graphify query "What concepts are related to spectator mode and Canvas?" \
  --graph graphify-out/graph.json \
  --budget 1200
```

La query ha trovato il cluster attorno a `Canvas()` con componenti/import collegati. Nota: sembra più traversal sul grafo che RAG semantico profondo; per domande vaghe può agganciarsi a un nodo solo.

## Prossimi passi possibili dopo le 6

1. Installare Graphify in modo persistente se utile:

```bash
uv tool install graphifyy
```

oppure continuare temporaneamente con:

```bash
. /tmp/graphify-venv/bin/activate
```

2. Provare su una cartella più significativa, ma non sull'intero vault subito:

```bash
graphify extract /home/fausto/Software/ScienceClick2 \
  --backend claude-cli \
  --out /tmp/scienceclick2-graphify-full \
  --token-budget 2500 \
  --max-concurrency 1
```

3. In alternativa provare solo una sottocartella Obsidian:

```bash
graphify extract "/home/fausto/Documents/Obsidian Vault/Projects" \
  --backend claude-cli \
  --out /tmp/graphify-obsidian-projects \
  --token-budget 2500 \
  --max-concurrency 1
```

4. Valutare una piccola patch upstream a Graphify per documentare/esporre meglio `claude-cli` nell'help, perché la feature esiste ma non è ben visibile.

## Ripresa valutazione dopo restart — 2026-06-07 18:10

Dopo il restart, `/tmp/graphify-venv` non risultava più disponibile e `graphify` non era nel PATH globale.

È stata provata una full extraction non invasiva su `/home/fausto/Software/ScienceClick2` usando `uvx --from graphifyy graphify` con output in `/tmp/scienceclick2-graphify-full`:

```bash
cd /home/fausto/Software/ScienceClick2
uvx --from graphifyy graphify extract . \
  --backend claude-cli \
  --no-cluster \
  --out /tmp/scienceclick2-graphify-full \
  --token-budget 2500 \
  --max-concurrency 1
```

Risultato: Graphify ha trovato `29 code, 11 docs, 1 papers, 11 images` e ha avviato AST extraction, ma tutti i 14 chunk semantici sono falliti perché `claude -p` restituiva `401 Invalid authentication credentials` anche su un prompt minimale. Quindi il blocker attuale è l'autenticazione non-interattiva Claude Code CLI, non Graphify.

È stata poi fatta una prova code-only, copiando in `/tmp/scienceclick2-code-only` solo file `.ts/.tsx/.js/.jsx/.json/.css/.mjs/.cjs` e manifest/config, ed eseguendo:

```bash
cd /tmp/scienceclick2-code-only
uvx --from graphifyy graphify extract . \
  --no-cluster \
  --out /tmp/scienceclick2-graphify-code-only
```

Risultato code-only riuscito:

```text
found 42 code, 0 docs, 0 papers, 0 images
wrote graph.json — 284 nodes, 431 edges
```

Sintesi su `src/`:

```text
src_nodes: 97
src_edges_touching_src: 226
relations: contains 79, imports_from 63, calls 44, imports 36, references 4
```

Componenti/funzioni riconosciuti includevano:

- `SceneEditorPage()`
- `SpectatorPage()`
- `Canvas()`
- `DropZone()`
- `HeaderBar()`
- `PracticePanel()`
- `WordList()`
- API route handlers `GET()`, `POST()`, `PATCH()`, `DELETE()`
- funzioni lib: `getOrCreateMatch()`, `submitTeamGuesses()`, `listAllScenes()`, `scenePublicUrl()`, ecc.

Query code-only testata:

```bash
cd /tmp/scienceclick2-graphify-code-only
uvx --from graphifyy graphify query "Canvas HeaderBar SpectatorPage scene editor" \
  --graph graphify-out/graph.json \
  --budget 1600
```

La query ha trovato un traversal utile attorno a `SpectatorPage()`, `HeaderBar()` e `Canvas()`, includendo `SceneEditorPage()`, `DropZone()`, `getTermLabel()`, `WordList.tsx`, `PracticePanel.tsx`, `i18n.ts`, import e call edges.

Osservazione: il code-only includeva anche JSON di scene e skill duplicati (`.agents`, `.codex`), che inquinano il grafo. Per una prova migliore conviene creare corpus filtrato con solo `src/`, `package.json`, `tsconfig.json`, `next.config.ts`, `PROJECT.md`, `README.md`, e magari escludere immagini/PDF finché Claude CLI non è riautenticato.

## Link correlati

- [[Projects/ScienceClick2]]
- [[Hermes/External AI CLIs]]
- [[Hermes/AI CLI Quotas]]
