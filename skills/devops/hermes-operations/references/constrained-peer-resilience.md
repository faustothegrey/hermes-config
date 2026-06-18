# Constrained Peer Resilience

Pattern for making a resource-constrained Hermes peer (e.g. old ARM SBC running a free-tier model with intermittent 401 quota failures) self-healing without babysitting.

## Problem

A Hermes peer on limited hardware (aarch64, low RAM, already swapping) uses a free-tier LLM that intermittently returns 401 when quota is exhausted. Hermes agent loop aborts on the 401, gateway stays up but the agent is frozen. When quota resets, the agent remains dead — needs a user prompt or restart to revive.

## Architecture

Two independent layers, each lightweight enough for constrained hardware:

```
PEER (e.g. 192.168.178.105)          ORCHESTRATOR (e.g. N56VV)
┌──────────────────────────┐         ┌───────────────────────────┐
│ watchdog.sh              │         │ heartbeat.py              │
│  systemd timer, 10 min   │         │  cron no_agent, hourly    │
│  curl /health            │ ◄────── │  HTTP GET /health         │
│  restart w/ cooldown     │         │  append JSONL log         │
│  bash only, ~1KB         │         │  silent, no alerts        │
└──────────────────────────┘         └───────────────────────────┘
```

### Layer 1: Local watchdog (on the peer)

Bash script, run by systemd timer every 10 minutes:
- `curl -sf --max-time 10 http://127.0.0.1:8642/health`
- If 200 → log "OK", exit 0
- If unreachable → check cooldown lock file
  - If lock < 15 min old → skip (anti-storm)
  - Else → `systemctl --user restart hermes-gateway`, touch lock, verify

Design constraints for constrained hardware:
- Bash only (no Python interpreter startup cost)
- Single curl call per tick
- Log append only, no log rotation logic
- Cooldown via stat-based lock file (no process tracking)

Deployment commands (run as root on the peer, or via SSH):
```bash
# Copy script
scp peer-watchdog.sh root@<peer>:/root/.hermes/scripts/watchdog.sh
ssh root@<peer> chmod +x /root/.hermes/scripts/watchdog.sh

# Create systemd units
# ~/.config/systemd/user/hermes-watchdog.service (Type=oneshot, ExecStart=%h/.hermes/scripts/watchdog.sh)
# ~/.config/systemd/user/hermes-watchdog.timer (OnCalendar=*:0/10, Persistent=true)

ssh root@<peer> systemctl --user daemon-reload
ssh root@<peer> systemctl --user enable --now hermes-watchdog.timer
```

### Layer 2: Remote heartbeat (from the orchestrator)

Python script, cron `no_agent=True`, hourly:
- HTTP GET to peer's `/health`
- Appends one JSONL line: `{ts, peer, status, platform, http_status}`
- No LLM cost, no delivery, silent unless queried

The log file can be read back to answer "what was peer105 doing over the last N hours?"

### SSH key setup (prerequisite)

When the peer API is unreliable (due to 401 freezes), use SSH for deployment:
```bash
# On orchestrator, copy key to peer:
ssh-copy-id -i ~/.ssh/id_rsa.pub root@<peer>
```

The orchestrator's Hermes process runs as a user service; use that user's key.

## Why no LLM in the watchdog/heartbeat

- LLM calls burn free-tier quota and can themselves trigger 401
- `no_agent=True` scripts are deterministic, cheap, and never freeze
- The LLM is the thing that's broken — don't use it to fix itself

## Pitfalls

- **System clock can be wrong** on old ARM boards (no RTC backup). Timestamps in logs will drift but the cooldown mechanism uses `stat -c %Y` (filesystem mtime) which is monotonic enough for anti-storm purposes even with a drifted clock.
- **Don't poll too often**. 10 minutes is fine for a watchdog; 1 minute is wasteful on constrained hardware.
- **/health alone won't detect a frozen agent with a live gateway**. That upgrade (v2) requires either log-activity checks or `/v1/runs` ping attempts — but those risk triggering 401s. Add only after observing v1 behavior.
- **`systemctl --user` needs the session bus**. If running from a non-login context, prefix with `XDG_RUNTIME_DIR=/run/user/$(id -u)` or run via the systemd timer which has the correct environment.

## Layer 3: Autonomous project loop (meta-loop)

When the user wants to be *completely out of the loop* — not just monitoring, but actively driving a multi-phase project on a constrained peer — add a third layer: an agent-driven cron job on the orchestrator that serves as the project's autonomous heartbeat.

This is NOT a watchdog (which reacts to failures) or a heartbeat (which passively logs). It's a **self-driving project manager** that wakes periodically, assesses state, takes one small step, documents progress, and self-regulates.

### Pattern

```
ORCHESTRATOR cron (every 4-6 hours, LLM-driven)
  📖 READ Obsidian project note   ← durable memory across runs
  🔍 CHECK peer health            ← via mcp_hermes_peers + heartbeat log
  🧠 DECIDE next atomic step      ← one small, safe action
  🔧 EXECUTE                      ← SSH to peer, file tools, etc.
  📝 UPDATE Obsidian project note ← operation log + phase status
  🧘 SELF-REGULATE                ← skip if unstable, pause if enough
```

### Key design rules

1. **Obsidian is the loop's memory**. The cron prompt tells the agent to read a specific Obsidian note at the start of every run. That note contains the master plan, current phase, completed tasks, and an operation log. The agent updates it before exiting.

2. **One step per wake-up**. No rushing. A 4-hour cadence means 5-6 steps per day. Each step should be atomic — a single file edit, a single config check, a single diagnostic probe.

3. **Self-regulation built into the prompt**. The cron prompt explicitly instructs the agent to:
   - Skip the cycle if the peer is unstable (diagnose only)
   - Stop after one step even if there's more to do
   - Never attempt risky changes without stabilization first
   - Log "stable, nothing to do" when appropriate

4. **Local delivery only**. `deliver='local'` — the user reads the Obsidian note to catch up, not their chat. No alerts, no notifications.

5. **SSH for deployment, not the peer API**. When the peer's agent is frozen, the peer API is unreliable. Use `ssh root@<peer>` for all deployment and diagnostic commands.

### Cron job shape

```
cronjob(
  action='create',
  name='Peer105 Autonomous Loop',
  schedule='0 6,10,14,18,22 * * *',   # 5x/day
  skills=['hermes-agent'],
  deliver='local',
  prompt='''You are the Peer105 Resilience autonomous loop.
Read the Obsidian project note, check peer health, take ONE small
step, document, self-regulate. ...'''
)
```

### Why not no_agent=True for the meta-loop

Unlike the watchdog and heartbeat (which are purely mechanical), the autonomous loop needs **reasoning**: assessing state, picking the right next step, diagnosing anomalies, deciding to skip a cycle. An LLM is appropriate here as long as it runs on the orchestrator (not the constrained peer) and the cadence is low (4+ hours).

### Memory compression

When using Obsidian as the project's durable memory, keep Hermes permanent memory compact: only essential pointers and paths. Move detailed topology, command recipes, troubleshooting history, and peer status into Obsidian notes. A Hermes memory entry for this project should look like:

```
peer105 (192.168.178.105): Fedora 30 aarch64, SSH root@. Watchdog + loop attivi.
  [[Hermes/Peer105 Resilience Project]], [[Hermes/Peer Mesh]]
```

Not a paragraph of implementation detail — that lives in Obsidian.
