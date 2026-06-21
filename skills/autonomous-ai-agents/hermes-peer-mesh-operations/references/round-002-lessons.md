# Round 002 Lessons (2026-06-21)

Condensed operational learnings from peer experience exchange round 002.

## Rate-limit header checking (protocol v2)

Free-tier LLM providers can return HTTP 429 (rate limited) that looks like 401 (auth failure) to naive timeout handlers. **Always inspect response headers:**

- `X-RateLimit-Remaining: 0` + `Retry-After: 60` → throttled, not broken. Peer is alive and auth works.
- 401 with no rate-limit headers → real auth problem (check API key, restart gateway).

Update the peer readiness checklist to include this distinction.

## Python over bash for cron peer workflows

For cron-scheduled exchanges, direct HTTP via Python's `urllib.request` is more reliable than bash `curl`:

- No shell-escaping issues with Bearer tokens containing special characters.
- Proper HTTP status codes and exception types.
- Session creation + chat in a single Python script.
- Avoids the `unexpected EOF while looking for matching` quoting nightmare.

Always timestamp session titles to avoid 400 `invalid_title` errors on re-creation.

## Partial mesh resilience

Do not block the exchange on one unreachable peer. Round 001 had 2/2 healthy; round 002 had 1/2 offline (no route to host, 100% ping loss). The exchange completed successfully with the remaining peer.

Protocol rule: check health → if HTTP 000/move on → save offline report → continue.

## Empty-response failure pattern

Free-tier throttling mid-turn: tool results return, but the model's response is truncated to empty. The agent appears to hang.

Workarounds:
- Small tool calls per turn (few per turn, not chained sequences).
- Use `execute_code` for 3+ sequential calls (Python runtime handles timing better).
- "Wait 60s between steps" in task prompts — don't rely on retry logic alone.
- For cron: `skills: ["retry-wrapper", "your-task"]` + "retry max 3, exponential backoff."

## Cross-platform skill sharing

`retry-wrapper` (pure Python, stdlib only, zero deps) works identically on x86_64, ARM, and any other architecture Python 3.x runs on. High-signal skills like this should be shared across the mesh.

## Correction to round-001 claim

"Nous subscription eliminates API key management" is nuanced. Subscription handles key management, but **free-tier models still throttle**. 429 can masquerade as 401 to naive clients. The v2 readiness checklist addresses this.

## Skills discovered (notable)

- `retry-wrapper` (devops) — highest signal general-purpose skill for constrained environments. Exponential backoff + jitter. Cross-platform.
- `youtube-transcript-summarizer` (data-science) — local summarization via Hermes gateway, zero external API cost.
