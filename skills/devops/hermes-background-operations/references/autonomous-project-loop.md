# Autonomous LLM-Driven Project Loop Pattern

## When to use
The user wants Hermes to run a slow, multi-phase project completely
autonomously over days/weeks — one small atomic step per cron wake-up.
The user is deliberately out of the loop and catches up via Obsidian
and optional recap emails.

## Architecture
```
CRON JOB (ogni 4-6h, agent-driven)
  ├── READ Obsidian project note (full state)
  ├── CHECK target health (heartbeat log + /health)
  ├── DECIDE one atomic step
  ├── EXECUTE (SSH, API calls, file ops)
  ├── DOCUMENT in Obsidian (Operation Log)
  └── SEND recap email via himalaya (optional)
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
- `deliver: local` — output saved to session store only. User must
  check Obsidian. Easy to miss. Add a himalaya recap step.
- `deliver: email:address` — requires gateway email platform configured.
- Best practice: `deliver: local` + prompt step that sends recap via
  himalaya (see below).

### Prompt structure
Include these sections:
1. Goal and context
2. Protocol (read → check → decide → execute → document → email)
3. Constraints (peer limits, never alert user, one step per run)
4. Memory strategy (re-read Obsidian before/after)
5. Self-regulation (when to do nothing, when to escalate)

## Himalaya recap email (when gateway email not configured)

Add as the last step of the cron prompt:

```
6. SEND RECAP EMAIL via himalaya:
   - Write email to /tmp/<project>-recap-<N>.eml
   - Format: From: user@virgilio.it, To: user@gmail.com
   - Subject: Project Loop #N — HH:MM CEST (OK/FAIL)
   - Body: actions done, outcome, fixes needed, next task
   - Send: cat /tmp/<file>.eml | himalaya message send -- -
```

Raw message format:
```
From: fausto.lelli@virgilio.it
To: fausto.lelli@gmail.com
Subject: Peer105 Loop #1 - 06:00 CEST (OK)
Content-Type: text/plain; charset=UTF-8

<body>
```

Pipe to himalaya: `cat /tmp/file.eml | himalaya message send -- -`

## Pitfalls

- Skill overflow: the `hermes-agent` skill is ~200KB. Loading it
  into a cron job silently kills the agent. Use `skills: []`.
- Silent failure: `deliver: local` + no email = user has no idea
  what happened. Always add a recap step if the user wants visibility.
- Memory bloat: don't store task progress in Hermes memory. Use
  Obsidian as the durable project log.
- Manual trigger confusion: `cronjob(action='run')` on a cron job
  with a large loaded skill can create a session that appears empty.
  The scheduled run may have succeeded independently — always check
  the Obsidian note for ground truth, not just the session list.
