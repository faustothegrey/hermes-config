---
name: research-intelligence-workflows
description: "Research intelligence umbrella: academic search, feeds, prediction markets, knowledge bases, and paper-writing workflows."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [research, arxiv, blogs, rss, llm-wiki, polymarket, papers]
---

# Research Intelligence Workflows

Use this class-level skill for research and intelligence tasks: academic paper discovery, RSS/blog monitoring, prediction-market data, compounding markdown knowledge bases, and research-paper writing.

## Academic search

Use arXiv for ML/AI/math/physics papers by keyword, author, category, or ID. Preserve paper IDs, titles, authors, dates, abstracts, and links. For full papers, extract PDFs when available and cite the source.

## Blog/feed monitoring

Use blog/RSS/Atom monitoring for ongoing content tracking. Prefer feed discovery first, then HTML scraping fallback only when needed. Track read/unread state when the user wants monitoring rather than one-off search.

## Prediction-market data

Use Polymarket/public market APIs for event probabilities, markets, prices, orderbooks, and histories. Distinguish market-implied probability from factual truth and note liquidity/spread when relevant.

## LLM Wiki / compounding knowledge bases

Use markdown wiki workflows when research should accumulate over sessions. The goal is synthesized, interlinked knowledge with contradictions and provenance tracked, not raw dumping of every source.

## Research-paper writing

For ML/AI research papers, cover the full lifecycle: experiment design, execution, analysis, writing, review, revision, and submission. Keep this iterative: results drive new experiments; reviews drive new analysis.

## Source quality and citations

- Prefer primary sources: papers, official docs, datasets, APIs.
- Use URLs/IDs in notes so claims can be rechecked.
- Separate evidence, inference, and speculation.
- For literature reviews, group by method/claim rather than chronological order only.
