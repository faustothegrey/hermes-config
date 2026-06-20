# Autonomous LLM-Driven Project Loop Pattern

## When to use

The user wants Hermes to run a slow, multi-phase project completely
autonomously over days/weeks — one small atomic step per cron wake-up.
The user is deliberately out of the loop and catches up via Obsidian
and optional recap emails.

## User input protocol (Research Queue)

The loop reads topics from an Obsidian note (e.g. `[[Hermes/Research Queue.md]]`)
that acts as a **user-driven input queue**. The user seeds topics via any
semantically equivalent phrase expressing "I want automatic updates on these
topics" — no rigid trigger string required.

**Three item types:**

| Format | Peer | Action |
|--------|------|--------|
| `https://youtube.com/watch?v=ID — descrizione` | peer105 | Transcribe specific URL |
| `video "topic description"` | peer105 | Search YouTube for topic, pick best video, transcribe it |
| `web "search query"` | peer106 | Web search + extract + summarize |

**Pacing:** max 1 video + 1 web per cron tick; max 3-4 videos + ~10 articles
per day total.

## Architecture

```text
CRON JOB (ogni 4-6h, agent-driven)
  ├── READ Research Queue from Obsidian
  ├── IDENTIFY next "Da fare" item
  ├── DELEGATE to peer (105 for video, 106 for web)
  ├── VERIFY Obsidian note was created
  ├── UPDATE Research Queue (move to "Completati")
  └── SEND recap email via himalaya
```

## Hermes memory rule (critical)

Keep Hermes persistent memory to the bare minimum for this project:
- Attempt count
- Last result (OK/FAIL)
- Next run time
- Pointer to Obsidian note

EVERYTHING else (phase progress, discoveries, detailed logs, system
state, decisions) goes in the Obsidian project note. The cron agent
MUST re-read the full Obsidian note at the start and update it at the
end of every run.

## Cron job setup

### Do NOT load large skills

Loading a documentation skill like `hermes-agent` (~200KB of markdown)
inline will overflow the context window or hit the 3-minute cron hard
interrupt before the agent can respond. Keep `skills: []` and embed all
operational instructions in the prompt itself.

### Delivery

- `deliver: local` keeps the cron output accessible in the session store.
- **Himalaya email recap is now standard** (see below) — the user gets
  a concise summary at fausto.lelli@gmail.com after every run.
- Do NOT rely on `deliver: local` alone for user visibility.

### Prompt structure

Include these sections:

1. **Goal and context** — what the loop does, who the peers are
2. **Queue protocol** — read Research Queue, identify item type, delegate accordingly:
   - YouTube URL → peer105: transcribe specific video
   - `video "topic"` → peer105: search YouTube, pick best, transcribe, summarize
   - `web "query"` → peer106: web search + extract + summarize
3. **Constraints** — max 2 items/run (1 video + 1 web), slow and deliberate
4. **Memory strategy** — re-read Obsidian before/after, update Research Queue
5. **Email step** — compose and send himalaya recap (see below)
6. **Self-regulation** — skip when queue is empty, retry on peer failure

## Himalaya recap email

Add as the last step of every run — not optional, not conditional:

```text
6. SEND RECAP EMAIL via himalaya:
   - Write email content to /tmp/research-loop-report-$(date +%s).eml
   - Raw MIME format:
     From: fausto.lelli@virgilio.it
     To: fausto.lelli@gmail.com
     Subject: Research Loop — YYYY-MM-DD HH:MM
     Content-Type: text/plain; charset=UTF-8

     (body: what was processed, key findings, links to Obsidian notes)
   - Send: cat /tmp/<file>.eml | himalaya message send -- -
```

## Pitfalls

- Skill overflow: the `hermes-agent` skill is ~200KB. Loading it
  into a cron job silently kills the agent. Use `skills: []`.
- Silent failure: `deliver: local` + no email = user has no idea
  what happened. Always add the himalaya recap step.
- Memory bloat: don't store task progress in Hermes memory. Use
  Obsidian as the durable project log.
- Manual trigger confusion: `cronjob(action='run')` on a cron job
  with a large loaded skill can create a session that appears empty.
  The scheduled run may have succeeded independently — always check
  the Obsidian note for ground truth, not just the session list.
- Botched trigger matching: the user's trigger phrase is flexible,
  not literal. Any semantically equivalent intent should work
  ("aggiungi questi temi", "tienimi traccia di", "vorrei aggiornamenti su").
  Do not require a fixed magic phrase.
- When peer105 searches YouTube for a `video "topic"`, instruct it to
  pick a recent, high-quality video (preferably under 30 min) relevant
  to the topic. Do not fetch paginated search results — one good video
  per topic per run is enough.
