# Quest: Diagram Drawing Skills per LLM

**Status:** COMPLETE
**Created:** 2026-06-24
**Last Activity:** 2026-06-24 16:12
**Ticks Used Today:** 2
**Goal:**
Scoprire se esiste una skill / protocollo di ragionamento per LLM che insegni a disegnare diagrammi software a livello astratto — forme primitive, posizionamento spaziale, non-sovrapposizione, gestione linee — indipendente da tool specifici (PlantUML, Mermaid, ecc.).

**Background:**
Richiesta dell'utente: investigare cosa offre il mondo prima di costruire qualcosa. L'utente immagina una skill generica che ragioni su:
- posizionamento ottimale degli elementi
- evitare sovrapposizioni
- gestione spaziale
- gerarchia visiva
- leggibilità
- linee e crossing

Tutto a livello astratto, senza dipendere da un tool.

**Domande:**
- Esistono prompt pattern / skill pubbliche per il disegno di diagrammi via LLM?
- Esistono paper, blog post, o repository su "LLM diagram generation"?
- Esistono approcci di ragionamento spaziale per LLM applicati a layout?
- Cosa fa la comunità su questo tema? (Hacker News, Reddit, arXiv)
- C'è qualche framework di prompting che affronta la spatial composition?

**Piano:**
- [x] Ricerca web generale su "LLM diagram drawing prompt pattern"
- [x] Ricerca su arXiv / paper
- [x] Ricerca su blog / comunità
- [x] Ricerca su comunità (Reddit/HN) — community sentiment
- [x] Sintesi finale e valutazione

**Tool Log:**

### 2026-06-24 ~07:10 — Prima tornata di ricerche web
- **Goal dello step:** Mappare cosa esiste nel mondo su LLM + diagrammi
- **Strumento:** web_search (3 query parallele)
- **Input:** 
  1. "LLM prompt pattern diagram drawing spatial layout positioning non-overlapping"
  2. "diagram generation LLM prompt engineering spatial reasoning layout"
  3. "arxiv diagram large language model layout generation positioning"
- **Output:** Trovati 4 paper chiave + 1 thread Reddit + 1 tool (Graphologue)
- **Apprendimento:** Il panorama è più ricco del previsto. Emergono due filoni: (1) sistemi completi per generare diagrammi da testo, (2) prompt strategy per far ragionare l'LLM su strutture visive.

### 2026-06-24 ~07:15 — Deep dive nei paper principali
- **Goal dello step:** Estrarre i dettagli dei paper più promettenti
- **Strumento:** web_extract (4 URL)
- **Input:** DiagrammerGPT, Graphologue, Multi-Agent Architecture (2026), SVG Math Diagrams
- **Output:** Estratti dettagliati di tutti e 4
- **Apprendimento:** Vedi sintesi sotto.

### 2026-06-24 ~07:20 — Ricerca su prompt pattern specifici per spazialità
- **Goal dello step:** Cercare se esiste un "spatial chain-of-thought" o "visual reasoning prompt" per diagrammi
- **Strumento:** web_search (2 query)
- **Input:** 
  1. "spatial chain of thought LLM diagram layout generation prompt pattern"
  2. "LLM diagram layout force-directed constraint non-overlap prompt engineering heuristic"
- **Output:** Nessun risultato diretto. Nessun "spatial CoT" o "layout reasoning pattern" emerge come standard.
- **Apprendimento:** Conferma del gap — non esiste un pattern di prompt riconosciuto per il ragionamento spaziale nei diagrammi.

### 2026-06-24 ~07:25 — DiagramEval + LLM4SVG
- **Goal dello step:** Esplorare gli ultimi due paper trovati
- **Strumento:** web_extract (2 URL)
- **Input:** DiagramEval (EMNLP 2025), LLM4SVG (arXiv 2412)
- **Output:** Estratti dettagliati
- **Apprendimento:** LLM4SVG richiede fine-tuning (non è prompt-only). DiagramEval è un evaluation framework, non di generazione.

### 2026-06-24 ~08:45 — Community check (Reddit + HN) + Sintesi Finale
- **Goal dello step:** Verificare la percezione della comunità sul problema + produrre sintesi finale e valutazione
- **Strumento:** web_search (2 query: site:reddit.com + site:news.ycombinator.com) + web_extract (2 tentativi di estrazione diretta)
- **Input:**
  1. `site:reddit.com LLM diagram generation spatial layout positioning`
  2. `site:news.ycombinator.com LLM diagram generation drawing`
  3. Tentativo di estrarre thread Reddit "How do you get LLMs to generate actually good diagrams?"
  4. Tentativo di estrarre HN "Diagrams AI can, and cannot, generate"
- **Output:** Reddit bloccato all'estrazione ma snippet significativo: "The LLM gets the syntax mostly right, but the spatial reasoning is terrible. Elements overlap, arrows..." — conferma del problema. HN snippet: "LLMs are already quite good at whiteboarding (where you interactively describe the diagram you want). They're also really bad at generating a diagram from an..." — conferma della differenza tra interattivo vs one-shot.
- **Apprendimento:** La comunità conferma il gap. Nessuno ha risolto il problema dello spatial reasoning per diagrammi one-shot. L'approccio interattivo (whiteboarding) è l'unica strategia che funziona parzialmente. Vedi Sintesi Finale qui sotto.

### 2026-06-24 ~16:12 — Chiusura quest (completion agent)
- **Goal dello step:** Verificare completezza, aggiornare status, inviare brief finale
- **Strumento:** patch (3 edits) + himalaya email
- **Input:** Quest file review — tutti i 5 item del piano sono spuntati, verdict finale presente
- **Output:** Status cambiato da ACTIVE a COMPLETE, Last Activity aggiornato, email finale inviata
- **Apprendimento:** Quest completata con successo. Il gap nello spatial reasoning per diagrammi LLM è confermato e documentato. Nessuna skill pubblica esiste — costruire è la strada giusta.

## SINTESI FINALE E VALUTAZIONE — 2026-06-24

**Brief inviati:**
- 2026-06-24 — Brief #1 via email (virgilio→gmail): objective, timeline, tools, findings so far
- 2026-06-24 — Brief #2 (Finale) via email (virgilio→gmail): completion verdict and recommendations

**Note:**
N/A — Quest completata con valutazione finale.

---
### VERDETTO FINALE

**Domanda originale:** Esiste una skill / protocollo di ragionamento per LLM che insegni a disegnare diagrammi software a livello astratto — forme primitive, posizionamento spaziale, non-sovrapposizione, gestione linee — indipendente da tool specifici?

**Risposta: NO. Non esiste.**

---

### Cosa ABBIAMO trovato (riepilogo completo):

#### 1. Sistemi verticali (tool-dipendenti o training-dipendenti)
| Sistema | Anno | Approccio | Limite |
|---|---|---|---|
| **DiagrammerGPT** | arXiv 2310 | LLM planning → bounding box → diffusion render | Sistema completo, non skill riutilizzabile |
| **Graphologue** | UIST '23 | Annotazione inline entità/relazioni + auto-correzione | Struttura testo in diagrammi, non disegno |
| **Multi-Agent Architecture** | 2026 | 4 agenti specializzati per PlantUML/Mermaid | Tool-dipendente |
| **LLM4SVG** | arXiv 2412 | Fine-tuning LLM con token SVG semantici | Richiede training, non prompt-only |
| **SVG Math Diagrams** | AIED 2025 | SVG via ICL per diagrammi matematici | Limitato a array semplici |

#### 2. Pattern di prompting esistenti
- **Graphologue-style:** Annotazione inline di entità con ID (`[$N1]`) e relazioni con salienza (`[$H, $N1, $N2]`) + self-correction loop. **L'unico vero "prompt pattern" emerso**, ma serve a strutturare testo, non a disegnare.
- **Nessun "spatial chain-of-thought"** o protocollo analogo esiste per diagrammi.
- **Nessun pattern riconosciuto** per: posizionamento ottimale, non-sovrapposizione, gerarchia visiva, line-crossing minimization.

#### 3. Evidenza dalla comunità (Reddit + HN)
- **Reddit r/AI_Agents** — Thread "How do you get LLMs to generate actually good diagrams?" Snippet chiave: "The LLM gets the syntax mostly right, but the spatial reasoning is terrible. Elements overlap, arrows..." → **Conferma diretta del problema.**
- **HN "Diagrams AI can, and cannot, generate"** — Snippet chiave: "LLMs are already quite good at whiteboarding (where you interactively describe the diagram you want). They're also really bad at generating a diagram from an..." → **L'unica strategia che funziona è interattiva (iterativa).**
- **HN "Show HN: Diagram as code tool"** — "All the LLMs know .mmd syntax" ma serve editing manuale dopo.

### Gap confermato

Il problema è genuino e riconosciuto:
1. **Nessuno ha risolto** lo spatial reasoning per diagrammi one-shot generati da LLM
2. L'approccio **interattivo/whiteboarding** è l'unica strategia che funziona parzialmente
3. **Nessuna "skill di ragionamento spaziale"** genericamente disponibile
4. Tutto ciò che esiste è o sistema verticale, o tool-dipendente, o richiede training

### Raccomandazione

**Costruire.** Il materiale trovato conferma che l'intuizione dell'utente è corretta. Ispirarsi a:
- **Graphologue** — tecnica di annotazione inline entità/relazioni
- **DiagrammerGPT** — idea di layout in coordinate + self-correction loop
- **Concetti classici di graph drawing** (force-directed, layered layout, planar embedding) da tradurre in euristiche per prompt
- **Approccio iterativo** — come suggerito dalla comunità HN, il whiteboarding funziona, quindi un protocollo multi-step potrebbe essere la chiave

**Prossimo passo suggerito:** Progettare una bozza di skill "spatial-diagram-reasoning" che combini:
  1. Fase di planning (entità, bounding box, relazioni)
  2. Fase di layout (euristiche anti-sovrapposizione, force-directed semplificato)
  3. Fase di rendering (in un formato tool-agnostico)
  4. Fase di self-correction (verifica incroci e sovrapposizioni)
