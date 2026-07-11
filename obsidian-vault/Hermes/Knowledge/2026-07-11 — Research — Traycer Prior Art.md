---
title: "Traycer — Prior Art Survey (Q0)"
date: 2026-07-11
tags: [research, agenttalk, prior-art, multi-agent, orchestrator]
source: "https://traycer.ai/"
related: "~/research-agenda copy.md"
---

# Traycer — Prior Art Survey (Q0)

**Agenda reference:** Q0 — Competitive prior-art survey of multi-agent coding orchestrators
**Verdict:** **Adopt (adapt)** — convergent in goals, diverges in architecture. Strong reference for contract/consensus design.

---

## What Traycer Is

Desktop app (Linux AppImage, GitHub) that orchestrates multiple AI coding agents in a unified workspace. Bring-your-own-agent (BYOA) model: Claude Code, Codex, Gemini, OpenCode, Cursor — side by side.

**Key differentiator:** spec-first development. Plan → Execute → Review → Explain pipeline.

---

## Architecture Highlights

| Feature | Traycer | AgentTalk (our design) |
|---------|---------|----------------------|
| Agent model | BYOA (bring your own) | BYOA (same) |
| Coordination | "Walkie-talkies" + Worktrees protocol | MCP message bus + recorded events |
| Planning | Built-in PLAN skill | Deterministic FSM (fact_collection → discussion → proposal → endorsement → submittal) |
| Context | Shared filesystem, artifacts, decision history | Per-task via MCP |
| Transcript sharing | `agent.getTranscript` available | Not yet — planned (Q10) |
| Contract versioning | `versioned-stream-rpc` + `json-schema-fingerprint` | Binary contract-hash (our M19 blocker) |
| Multiplayer | Yes (shared workspace, human+agent) | Yes (PO + team) |
| Pricing | $0 BYOA / $10 Sync / $20-100 Pro | Not yet |

---

## What We Can Steal

1. **`json-schema-fingerprint`** — Traycer's approach to structural diffing instead of binary hash. Direct answer to Q2 (schema-fingerprint versioning). Read their `versioned-stream-rpc` implementation (LB-67 F4).

2. **`agent.getTranscript`** — cross-agent transcript visibility. Simple, elegant way to let agents see each other's work. Informs Q10.

3. **Worktrees protocol** — git worktree isolation for parallel agent execution. Relevant to Q6 (scope enforcement).

4. **Typed non-reply reasons** — 7-state model (turn-ended / exited / quiet / user-stopped / errored / awaiting-input / receiver-cancelled). Informs Q7 (failure taxonomy).

---

## Where We're Ahead

- **Deterministic FSM** vs Traycer's freeform "walkie-talkie" — our consensus model is harder but more auditable (as noted in LB-67 F5).
- **Self-hosting flywheel** — AgentTalk's core metric (human coordination burden falls) is not a Traycer goal.
- **MCP bus** — transport-agnostic, extensible. Traycer is desktop-app-bound.

---

## Next Steps

- [ ] Read Traycer's `versioned-stream-rpc` source (LB-67 F4) for schema-fingerprint details
- [ ] Read Traycer's `inbox.ts` for typed-reason model (LB-67 F1/F2)
- [ ] Compare with MetaGPT (next Q0 lead)