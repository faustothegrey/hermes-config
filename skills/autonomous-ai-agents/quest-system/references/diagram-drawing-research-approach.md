# Research Approach: LLM Diagram Drawing Skills

Captured 2026-06-24 from the "Diagram Drawing Skills per LLM" quest.

## Multi-phase research pattern used

This quest demonstrates a reusable research pattern for "is there a prompt pattern / skill for X?" investigations:

### Phase 1: Broad web sweep (3 parallel queries)
- Search with different framings: academic, community, tool-specific
- Record which results are papers vs blog posts vs tools vs discussions

### Phase 2: Deep extraction (web_extract on promising URLs)
- Extract full content from papers, blog posts, and tools
- Categorize: "vertical system" vs "prompt pattern" vs "training-dependent" vs "tool-dependent"

### Phase 3: Gap analysis
- Search for the specific missing piece (e.g. "spatial chain of thought")
- If no results emerge, that confirms the gap
- Also search for adjacent fields (graph drawing, force-directed layout)

### Phase 4: Community sentiment (web_search with site:reddit.com + site:news.ycombinator.com)
- Reddit and HN block web_extract. Use snippets from web_search descriptions.
- Note: r/AI_Agents and r/LocalLLaMA are the most relevant subreddits.
- HN search: use `site:news.ycombinator.com <topic>`.

### Phase 5: Final synthesis
- Tabular summary of all systems found
- Explicit "what does NOT exist" section
- Verdict + recommendation

## Systems catalogued (from this quest)

| System | Year | Approach | Key Limitation |
|--------|------|----------|----------------|
| DiagrammerGPT | arXiv 2310 | LLM planning → bounding box → diffusion render | Full system, not reusable skill |
| Graphologue | UIST '23 | Inline entity/relation annotation + self-correction | Structures text into diagrams, not drawing |
| Multi-Agent Architecture | 2026 | 4 agents: Selector→Generator→Validator→Refiner | Tool-dependent (PlantUML/Mermaid) |
| LLM4SVG | arXiv 2412 | Fine-tuning with semantic SVG tokens | Requires training, not prompt-only |
| SVG Math Diagrams | AIED 2025 | SVG via ICL for math diagrams | Limited to simple arrays |

## Key findings

1. **No generic spatial-diagram-reasoning skill exists** — confirmed gap
2. **Graphologue's inline annotation** (`[$N1]`, `[$H, $N1, $N2]` + self-correction) is the closest to a reusable prompt pattern
3. **The community is struggling with this** — Reddit/HN threads confirm the problem
4. **Interactive/whiteboarding approach works partially**; one-shot generation fails
5. **Recommendation: build a custom skill** inspired by Graphologue (annotation), DiagrammerGPT (layout planning + self-correction), graph-drawing heuristics, and iterative refinement

## Suggested skill architecture (from final recommendation)

A "spatial-diagram-reasoning" skill should have 4 phases:
1. **Planning** — entities, bounding boxes, relations
2. **Layout** — anti-overlap heuristics, simplified force-directed
3. **Rendering** — tool-agnostic output format
4. **Self-correction** — cross-check for overlaps and line crossings
