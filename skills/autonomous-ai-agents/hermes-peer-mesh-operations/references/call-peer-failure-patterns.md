# call_peer failure pattern — Round 003 (July 2026)

During the HMP protocol design round, `call_peer` was used to ask all peers for feedback on the SPEC. The results revealed two distinct failure modes:

## Peer105 — 401 Invalid API key

The API key stored in the orchestrator's peer-mesh.yaml/env did not match the key configured on peer105's gateway.

**Diagnosis:**
- `/health` returned 200 (liveness check passes without auth)
- `call_peer` returned 401 (authenticated endpoint fails)
- Root cause: the key may have been regenerated on peer105 without updating the orchestrator

**Lesson:** A `/health` 200 does not mean the peer is fully operational. Always check authenticated `/v1/capabilities` (or attempt a `call_peer`) to confirm mesh readiness. The `hermes-peer-mesh-operations` skill's verification ladder (health → capabilities → call_peer) catches this — use it.

## Peer106 — 429 Rate limit exceeded

The free-tier LLM provider quota was exhausted. The peer tried 3 retries internally before reporting the failure.

**Diagnosis:**
- `/health` returned 200
- `call_peer` succeeded in accepting the task but the agent's LLM calls returned 429
- After 3 retries, the peer returned: "API call failed after 3 retries: HTTP 429: The usage limit has been reached"
- The 429 was transient — the quota resets after a period (typically hours for free-tier)

**Lesson:** A peer with a free-tier model WILL hit quota limits. This is not an emergency. HMP addresses this with:
- `resource_exhausted` error code with `retry_after_s`
- Agent Card `rate_limits` declaration
- Auto-limitazione: peer rifiuta task invece di accettare e fallire

**Mitigation for cron/research loops:**
- Schedule heavy tasks during low-traffic periods
- Use the orchestrator's own web_search/web_extract for research, delegating to peers only for lightweight queries
- Include "wait 60s between steps" in cron prompts to pace the rate limit consumption