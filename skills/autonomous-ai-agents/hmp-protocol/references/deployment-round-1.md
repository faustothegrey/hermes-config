# HMP Deployment Round 1 — Notes

Session date: 2026-07-14
Orchestrator: peer84 (N56VV)
Coordinator: peer70 (RPi, 192.168.178.70, Hermes v0.17.0)

## Build

- SPEC v0.1 → written from scratch, inspired by AMB (kriszmac4) and Google A2A
- `hmp.py` ~680 lines stdlib-only: HMPBus (SQLite WAL), HMPServer (HTTP :8643), HMPClient
- Server running on peer70:8643 via `nohup python3 hmp.py 8643`
- 3 cron jobs (no_agent=True) registered on orchestrator, wrapping SSH to peer70

## Bug found & fixed

1. **expanduser in HMPBus** — `init_cron()` passed `~/.hermes/data/hmp/agent_messages.db` without expansion. HMPBus's `__init__` now calls `os.path.expanduser()`.

## Peer Reviews

### Round 1 (peer70)

Feedback from peer70 → 9 items:
- **BLOCKING**: ThreadingHTTPServer (was single-threaded), TERMINAL_STATES missing, utcnow() deprecated
- **RECOMMENDED**: message-router race condition, /health endpoint, auth docs, availability_window
- **NICE**: idempotency cleanup, log_message

### Round 2 (peer70 — after fixes)

All 9 items verified. **Approved** with one minor note: `cleanup_idempotency_keys` works on `messages` table (not separate registry).

### peer105 (tried but 401 Invalid API key)
### peer106 (tried but 429 quota exhausted)

Both failures documented as HMP use cases — the protocol handles these through error codes `invalid_request` and `resource_exhausted`.

## Current state

| Component | Status |
|---|---|
| hmp.py on peer70 | ✅ Running, fixed v0.2 |
| Server :8643 | ✅ Active, /health responds |
| message-router cron | ✅ Registered, delivered test message |
| watchdog cron | ✅ Registered |
| dream-engine cron | ✅ Registered |
| SSH wrapper cron pattern | ✅ Working |
| Full lifecycle test | ✅ send→delivered→working→heartbeat→completed |

## Files on peer70

```
~/.hermes/skills/autonomous-ai-agents/hmp-protocol/scripts/hmp.py
~/.hermes/scripts/hmp-message-router.py
~/.hermes/scripts/hmp-watchdog.py
~/.hermes/scripts/hmp-dream-engine.py
~/.hermes/hmp-config.json
~/.hermes/data/hmp/agent_messages.db (SQLite WAL)
~/.hermes/data/hmp/server.log
```

## Verification commands

```bash
# Health
curl -s http://192.168.178.70:8643/health

# Agent Card
curl -s http://192.168.178.70:8643/hmp/agent-card | python3 -m json.tool

# Send test message (from any peer)
python3 -c "
import sys; sys.path.insert(0,'/home/fausto/.hermes/skills/autonomous-ai-agents/hmp-protocol/scripts')
from hmp import HMPClient, new_message_id, now_iso
c = HMPClient('http://192.168.178.70:8643')
r = c.send_message({'hmp_version':'1.0','message_id':new_message_id(),'idempotency_key':new_message_id(),'from':'peer84','to':'peer70','type':'request','timestamp':now_iso(),'payload':{'task_type':'ping'}})
print(r)
"
```

## First real task executed

On 2026-07-14, the first production-like HMP task was completed:

**Request** (peer84 → peer70):
- task_type: research
- instruction: "Trova le ultime novità su RISC-V nel 2026"
- output_format: {summary, boards[], sources[]}

**Lifecycle**: pending → queued → delivered → working (heartbeat at 40%) → completed

**Result**: 7 RISC-V boards with prices (HiFive P550 ~$299-499, VisionFive 2 ~$35-90, Milk-V Mars ~$40-80, Banana Pi BPI-F3 ~$70-120, Milk-V Jupiter ~$150-250, Pioneer ~$2000+, CanMV-K230 ~$50-80). Sources: lucaberton.com, microcontrollerslab.com, riscv.org.

**Significance**: Proved end-to-end HMP flow with real tool calls (web_search + web_extract on peer70), heartbeat progress visible via poll, structured payload response.