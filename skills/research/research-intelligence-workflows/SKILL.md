---
name: research-intelligence-workflows
description: "Research intelligence umbrella: academic search, feeds, prediction markets, knowledge bases, and research-agenda / prior-art survey workflows."
version: 1.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [research, arxiv, blogs, rss, llm-wiki, polymarket, papers, prior-art, surveys]
---

# Research Intelligence Workflows

Use this class-level skill for research and intelligence tasks: academic paper discovery, RSS/blog monitoring, prediction-market data, compounding markdown knowledge bases, research-paper writing, and structured prior-art surveys.

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

## Structured research agendas (prior-art surveys)

When the user provides a multi-question research agenda (a markdown file with prioritized open questions, each with leads, decisions to inform, and provenance tags):

1. **Read the agenda** — understand the priority tiers (A/B/C) and which question to tackle first
2. **Pick ONE lead per tick** — consume one research question or one lead per cycle. Do not batch.
3. **Method per lead:**
   - `web "specific query"` → peer106 (web research, has good LLM, limited RAM)
   - `https://youtube.com/watch?v=...` → peer105 (YouTube + transcript, python 3.7 constrained)
   - Direct: use web_search + web_extract from orchestrator for speed when demonstrating the process
4. **Produce a structured digest** in Obsidian `Hermes/Knowledge/YYYY-MM-DD — Research — <Topic>.md` with:
   - Frontmatter: title, date, tags, source, related agenda item
   - What it is (summary)
   - Architecture comparison (if comparing with own design)
   - What to steal / Where we're ahead
   - Verdict per entry: adopt / adapt (adopt with modifications) / skip / genuinely-novel
   - Next steps
5. **Log the verdict** back into the agenda document if applicable
6. **Update the Research Queue** — move processed item to Completati, link the digest, seed the next item
7. **Send email recap** — use Python `smtplib.SMTP_SSL` on port 465 directly (not himalaya, which requires IMAP first and fails on DNS). See references/virgilio-smtp.md for the credential chain and SSL workaround.
7b. **Verify email delivery** — after sending, check that the SMTP `send_message` call returned without raising an exception. Do NOT report "email sent" based on `himalaya message send` exit code alone — himalaya can exit 0 while the email is never delivered because its IMAP prerequisite silently failed. When running as a cron job, save the SMTP response or error to the run log so the orchestrator can audit it.
8. **Auto-seed next item** — when completing a research lead that naturally suggests a follow-up (e.g., "next compare with MetaGPT"), add the follow-up to `## Da fare` in the queue so the next tick picks it up automatically.

9. **Pitfall: queue formatting from peer edits** — when a peer agent (peer105/106) edits `Research Queue.md`, it may duplicate section headers (## In corso, ## Completati). The orchestrator must verify and fix queue formatting after each peer delegation.

10. **Pitfall: delegation-goal scope creep causes subagent timeout** — when delegating web research to peer106 or an internal subagent, the most common cause of timeout is a goal that asks for too much. A single delegation asking the subagent to "read the paper, read the entire GitHub repo source code, read 3-4 web articles, write a note, and update the queue" will time out at 600s on a constrained subagent (observed: 600s timeout with 11 API calls completed before the agent ran out of time). The fix: **scope to the minimum viable deliverable per delegation.** For a prior-art survey, this means:
   - **First delegation**: paper abstract/intro + 2-3 web articles → concise summary + verdict
   - **Second delegation (if needed)**: specific source-code or schema investigation, based on findings from the first pass
   - Never ask a subagent to read repo source code AND the paper AND web articles in one shot. If deep source-code analysis is needed, it's its own delegation with its own narrow goal.
   - When the subagent times out, do NOT retry with the same broad goal — always narrow the scope first.
   - Verification: check the Obsidian note was created and the queue was updated before declaring success, even when the subagent reports completion.

11. **Pitfall: cron prompts drift out of sync with skill** — the dual-peer autonomous loop cron job has its own prompt hardcoded at creation time. If the skill updates the email-sending method (himalaya -> Python smtplib), the cron prompt still carries the old instructions. The cron agent follows its own prompt, not the skill. The fix: after patching the skill, also update the cron job with `cronjob action=update prompt=...` or point the cron prompt to a script that delegates to the skill. If you cannot edit the cron prompt immediately, add a verification step (step 7b) so the cron agent catches the failure even while running stale instructions.

12. **When user asks "what happened overnight / last night"**: The research loop ticks at 7,10,20,22,0 — the "night shift" spans the 22:00 (previous evening), 00:00 (midnight), and 07:00 (morning) ticks. To answer efficiently, inspect in this order:
    a. **Cron job last_run_at** — `cronjob action=list` on job `19c9f58c1c43` shows when it last ran and its last_status. If last_run_at preceded the night shift, the loop had no items to process and stayed silent.
    b. **Research Queue completions** — read `Hermes/Research Queue.md` and check Completati section for entries dated today or yesterday. Each completed item has a link to the Knowledge digest.
    c. **Knowledge digests** — search `Hermes/Knowledge/` for notes dated today. These are the actual research output.
    d. **Email delivery** — check that the recap email was sent by reviewing the cron session transcript or checking for SMTP errors in the last run output. The loop sends email after every tick that produces output.
    e. **Cron session logs** — search for sessions with source=cron and name="Peer105+106 Autonomous Loop" to see actual run output. The cron job's deliver=local means output appears only in the cron session transcript, not in your chat.
    
    Common case: if the queue was already empty by the night ticks (all items completed earlier in the day), the loop skips silently with no output, no email, and last_run_at just confirms the tick fired. Tell the user the queue was empty and nothing was processed.

13. **Constraint**: peer105 and peer106 are ARM, Fedora 30, very low RAM — one step per tick max. No batch processing.

### Research Queue workflow

The Research Queue lives in Obsidian at `Hermes/Research Queue.md`. Format:

```
## Da fare
- [ ] web "query" — description → peer106
- [ ] https://youtube.com/watch?v=ID — description → peer105

## In corso

## Completati
- [x] web "done query" → [[wiki link to digest]] — verdict: adopt/adapt/skip
```

The dual-peer autonomous loop (cron job, tick schedule 0 7,10,20,22,0) consumes one item per tick and produces output in `Hermes/Knowledge/`.

### Decision-verdict vocabulary

When evaluating prior art against own design:
- **Adopt** — directly usable as-is
- **Adopt (adapt)** — usable with modifications
- **Skip** — not relevant or inferior to own approach
- **Genuinely-novel** — no prior art found, worth documenting as novel territory

## Source quality and citations

- Prefer primary sources: papers, official docs, datasets, APIs.
- Use URLs/IDs in notes so claims can be rechecked.
- Separate evidence, inference, and speculation.
- For literature reviews, group by method/claim rather than chronological order only.