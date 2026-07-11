# Prior-Art Survey Workflow — Session Reference

## Agenda format (from research-agenda copy.md)

The user's research agenda for AgentTalk uses this structure:

```
## N. Question name *(Tier A/B/C)*
**Our problem.** Why this matters.
**What to find out.** What to investigate.
**Leads (verify).** Named systems/papers/techniques to research.
**Decision it informs.** What architectural choice this research feeds.
**From.** Provenance tag (logbook/backlog reference).
```

Priority tiers:
- **Tier A** — do first (high leverage × high uncertainty)
- **Tier B** — important but lower urgency
- **Tier C** — nice-to-know

## Digest output format

Each lead produces a note in `Hermes/Knowledge/YYYY-MM-DD — Research — <Topic>.md`:

```markdown
---
title: "<Topic> — Prior Art Survey (Q<N>)"
date: YYYY-MM-DD
tags: [research, <project>, prior-art, <topic>]
source: "<URL>"
related: "~/research-agenda copy.md"
---

# <Topic> — Prior Art Survey (Q<N>)

**Agenda reference:** Q<N> — <question name>
**Verdict:** adopt / adapt / skip / genuinely-novel

## What <Topic> Is

<summary>

## Architecture Highlights

| Feature | <System> | <Our Design> |
|---------|----------|--------------|
| <feature1> | <their approach> | <our approach> |

## What We Can Steal

1. <thing to adopt> — <what it solves>
2. ...

## Where We're Ahead

- <our advantage> — <why>

## Next Steps

- [ ] <next action>
```

## Dual-peer autonomous loop

- **peer105** (192.168.178.105, ARM Fedora 30, very low RAM) — YouTube video processing
- **peer106** (192.168.178.106, ARM Fedora 30, very low RAM) — web research
- **Orchestrator** (peer84, N56VV) — where the cron job runs and this session lives
- **Cron schedule**: 0 7,10,20,22,0 * * * (ticks at 7, 10, 20, 22, midnight)
- **Research Queue**: `Hermes/Research Queue.md` in Obsidian vault
- **Output directory**: `Hermes/Knowledge/` in Obsidian vault
- **Email delivery**: Python smtplib.SMTP_SSL on port 465 (fallback from himalaya — see `references/virgilio-smtp.md` for credential chain and SSL workaround)
- **Cron IDs**: `19c9f58c1c43` (Peer105+106 Autonomous Loop)
- **Email verification**: Do NOT rely on himalaya exit code 0 alone — it can succeed while delivery silently fails. Verify via the SMTP `send_message` return / exception in the cron run log.

## Example: Traycer (first Q0 lead processed 2026-07-11)

- Digest: `Hermes/Knowledge/2026-07-11 — Research — Traycer Prior Art.md`
- Verdict: **Adopt (adapt)** — convergent goals, diverges architecture
- Key steals: json-schema-fingerprint (Q2), agent.getTranscript (Q10), typed non-reply reasons (Q7), worktrees protocol (Q6)
- Where ahead: deterministic FSM (stronger than freeform walkie-talkie), self-hosting flywheel, MCP bus
- Next in queue: MetaGPT (auto-seeded by peer106 after completing Traycer — the consensus protocol and contract-versioning angle was the natural follow-up to the Traycer json-schema-fingerprint finding)
- **Auto-seed pattern**: When a lead naturally suggests a follow-up (Traycer → MetaGPT for consensus protocol comparison), the cron agent or peer should add the follow-up to `## Da fare` in the queue so the next tick picks it up automatically. This keeps the agenda moving without manual intervention.

## Pitfalls

### Peer agents overwrite queue structure
When delegating queue editing to peer106, the peer may add entries in a different format or accidentally duplicate section headers (## In corso / ## Completati appearing twice). After each delegation, the orchestrator must read back the queue and fix formatting.

### Peer agents save to their own filesystem
When delegating note creation to peer105/106, the note is saved on the *peer's filesystem* — not the orchestrator's Obsidian vault. The note only exists on the orchestrator if:
- The peer uses `write_file` to write to a path the orchestrator can access (NFS, SSHFS, shared mount), OR
- The peer copies/syncs the file back, OR
- The orchestrator retrieves the content via `call_peer` and writes it locally.

Currently, peer105 and peer106 are standalone machines — their `/home/fausto/` is local. Workaround: instruct the peer to output key findings in its summary, then the orchestrator writes the note locally.

### Output path disagreement
The convention is `Hermes/Knowledge/YYYY-MM-DD — Research — <Topic>.md`, but if the peer is told a different path (e.g., `Projects/ScienceClick2/Research/`), it may use its own judgment. Always specify the canonical path explicitly in the delegation goal, and verify afterwards.