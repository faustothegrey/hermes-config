---
name: quest-system
description: "Long-running research investigations (quests): up to 3 in parallel, tracked in Obsidian, background advancement via cron, periodic email briefs. Tool- and resource-aware."
---

# Quest System

Trigger: the user says "I have a new quest for you" or equivalent.

## Core rules

1. **Up to 3 parallel quests.** Advances happen round-robin — one quest per tick.
2. **Optimize resources.** Before reinventing, check what already exists: Research Queue (peer105/106), Faro beacon (peer status), web_search, browser, terminal/journalctl, fact_store, session_search, Obsidian vault.
3. **If the quest goal is unclear, say so.** Ask for clarification immediately. This is critical.
4. **Delegate to peers what they can already do.** peer105 → YouTube transcription. peer106 → web search. Respect their limits: max 3-4 videos/day, ~10 articles/day — these are **shared across all quests**.
5. **Maximum ticks per quest per day:** 2. This spreads work evenly and respects peer/thermal constraints.

## Quest lifecycle

### 1. LAUNCH
When the user says "new quest":
- Ask for clarification if the goal is vague
- Create the quest file in `~/Documents/Obsidian Vault/Hermes/Quests/<quest-name>.md`
- If no cron exists yet, create one: every **4 hours** (6 ticks/day), round-robin over active quests
- Send an **email brief** (virgilio→gmail) with: objective, estimated timeline, planned tools
- Confirm to the user the quest has started

### 2. ADVANCEMENT (cron every 4h)
The background cron agent does mechanical work:
- Read all active quests from `Hermes/Quests/` (status: ACTIVE)
- Pick the one with the oldest last-activity that isn't WAITING_USER
- Determine the next step and execute it
- Log in the quest file: tool, input, output, learning
- If a strategic decision is needed → set `Status: WAITING_USER` and **send email** with summary
- Track shared resource consumption (peer105/106 daily usage) so we don't overshoot

### 3. CHECK-IN (in conversation)
When the user asks "how's the quest going?":
- Read the quest file from Obsidian
- Synthesize progress, results, blockers
- Ask whether to continue, change direction, or stop

### 4. INTERMEDIATE BRIEFS
Per quest, after meaningful progress or every 2-3 days:
- Send email (himalaya, virgilio→gmail) with:
  - What was done (tool log summary)
  - What was discovered
  - Next steps / blockers
- Only for urgent/interesting discoveries → Telegram

### 5. COMPLETION
- Write the conclusion in the quest file
- Set `Status: COMPLETE`
- Send final email summary
- If all quests are done, disable the advancement cron

## Quest file format

Folder: `~/Documents/Obsidian Vault/Hermes/Quests/`

```markdown
# Quest: <Name>

**Status:** ACTIVE | WAITING_USER | COMPLETE | CANCELLED
**Created:** YYYY-MM-DD
**Last Activity:** YYYY-MM-DD HH:MM
**Ticks Used Today:** 0

**Goal:**
<clear description>

**Background:**
<context>

**Questions:**
- <main question>
- <sub-questions>

**Plan:**
- [ ] <step 1>
- [ ] <step 2>

**Tool Log:**
### <Timestamp> — <Step Label>
- **Step goal:**
- **Tool:**
- **Input:**
- **Output:**
- **Learning:**

**Briefs Sent:**
- <date>

**Notes:**
```

## Cron advancement logic

Single cron job, every 4 hours:

```
schedule: "0 */4 * * *"
prompt (agent-mode):
  Read ~/Documents/Obsidian Vault/Hermes/Quests/*.md.
  Identify all quests with Status: ACTIVE (not WAITING_USER, not COMPLETE).
  Sort by last-activity ascending.
  Pick the first one whose ticks-used-today < 2.
  Advance it by one step. Log everything. Increment ticks-used-today.
  Reset all quests' ticks-used-today to 0 at 00:00 (first tick of the day).
  If a quest needs user input, set Status: WAITING_USER and send email.
  Skip quests that are waiting for user feedback.
```

On each tick, also:
- **Read `~/.hermes/quest-resources.json`** before spending peer105/peer106 resources.
- **Auto-complete finished quests:** after logging the step, scan the plan. If every `- [ ]` is now `- [x]`, set `Status: COMPLETE`, update `Last Activity`, and **send a final email summary** (himalaya, virgilio→gmail) with the verdict and recommendations.

## Completion detection

When advancing a quest, after logging the step:

1. **Check all plan items.** If every `- [ ]` is now `- [x]`:
   - Set `Status: COMPLETE` in the quest file
   - Update `Last Activity` timestamp
   - Send a final email brief with: final verdict, key findings, recommendations
   - If no remaining ACTIVE quests exist, disable the cron (`crontab -e`)
2. **No need to defer:** if only 1 unchecked item remains and you're about to take it, complete it in the same tick — don't leave the quest sitting on the last checkbox.

## Resource tracking clarification

- **Peer106** (priority #2) and **web_search** (priority #4) are separate resources with separate budgets.
- `web_search` calls from your own tool set do NOT count toward `peer106_searches_today` — that counter only tracks searches done via the peer106 agent.
- However, if you use `web_search` plus `web_extract` in heavy volume (>15 calls/day total), log it in `quest-resources.json` under a `direct_searches_today` key so you can monitor overall web-API load.
- Always read `~/.hermes/quest-resources.json` at the start of each cron tick to know your starting budget.

## Common pitfalls

- **web_extract on social/news sites fails.** Reddit, HN, and many forum platforms block extraction. Fallback: use the `description` field from `web_search` results — they often contain key snippets that are sufficient for community sentiment analysis.
- **Resource budget at midnight.** The first tick after 00:00 resets all counters. Check the `date` field in `quest-resources.json` — if it's yesterday's date, reset to 0 before proceeding.
- **Quest plan fully checked but status still ACTIVE.** This happens when the last step completes. Use the completion detection logic above rather than leaving it ACTIVE for the user to manually close.

**Resource tracking (shared across all quests):**
- Keep a running counter at `~/.hermes/quest-resources.json`:
  - `peer105_videos_today`
  - `peer106_searches_today`
  - Reset at 00:00
- If a quest needs peer105/106 but the daily budget is exhausted, log "deferred" and try next tick

## Tool selection priority

1. **Peer105** — YouTube transcript/download (for video-related quests)
2. **Peer106** — targeted web research (for broad information gathering)
3. **Research Queue** — if the quest can be fragmented into queueable items
4. **web_search** — quick searches that don't warrant a peer
5. **web_extract/browser** — extracting content from specific pages
6. **terminal/journalctl/dmesg** — system/kernel stuff (local)
7. **fact_store** — structured memory recall
8. **session_search** — past conversation context
9. **Obsidian vault** — existing knowledge base

## Email format for briefs

Subject: [Quest] <Name> — Brief <N>

Content:
- Current status
- What was done this period
- Key findings
- Blockers / decisions needed
- Next steps

## Storage

- Quest files: `~/Documents/Obsidian Vault/Hermes/Quests/`
- Resource tracking: `~/.hermes/quest-resources.json`
- Skill file: `quest-system` (this skill)
- Reference files: `references/diagram-drawing-research-approach.md` — multi-phase research pattern and systems catalog from the Diagram Drawing quest
