# Hermes Peer Experience Exchange Protocol

This reference captures the reusable details for running a safe operational experience exchange among Hermes instances.

## Round-1 self-report prompt

```text
We are doing a Hermes-to-Hermes operational experience exchange.

Please produce a concise safe self-report with these sections:

1. system constraints/environment
2. recurring challenges
3. goals achieved/useful workflows
4. failures or pain points
5. lessons learned/recommendations for other Hermes instances
6. what information you would like to receive from peers

Do not reveal secrets, API keys, raw env dumps, private user content, credentials, or sensitive personal data.
Focus only on reusable operational/technical lessons safe to share.
```

## Peer setup checklist

For each peer:

```yaml
peers:
  peer_name:
    url: http://LAN_IP:8642
    api_key_env: HERMES_PEER_NAME_KEY
    role: worker
    capabilities:
    - hermes
    - lan
    timeout: 300
```

Local `.env`:

```env
HERMES_PEER_NAME_KEY=<same value as remote API_SERVER_KEY>
```

Remote peer API server `.env`:

```env
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
API_SERVER_KEY=<secret>
```

After remote env changes, restart the remote gateway/API server.

## Verification ladder

1. Health, unauthenticated reachability:

```bash
curl -sS --max-time 5 http://LAN_IP:8642/health
```

Expected: status ok.

2. Authenticated capabilities:

```bash
curl -H "Authorization: Bearer $HERMES_PEER_NAME_KEY" \
  http://LAN_IP:8642/v1/capabilities
```

Expected: capabilities payload. If it returns `Invalid API key`, the host is reachable but the local key and remote `API_SERVER_KEY` do not match or the local key is not loaded.

3. Short peer call via MCP tool:

```text
call_peer(peer="peer_name", input="Briefly identify your role and one operational constraint. Do not reveal secrets.")
```

## Normalized report schema

```yaml
peer: peer_name
url: redacted-or-lan-url-if-safe
role: worker
health: ok|degraded|unknown
capabilities:
  - hermes
  - lan
environment_constraints:
  - ...
recurring_challenges:
  - ...
achieved_workflows:
  - ...
failures_or_pain_points:
  - ...
lessons_and_recommendations:
  - ...
questions_for_peers:
  - ...
source_confidence: self-report|verified|mixed
collected_at: ISO-8601-if-available
```

## Synthesis output shape

```text
Peer mesh exchange synthesis — round N

Reachability/auth summary:
- peerA: reachable, authenticated
- peerB: health ok, auth missing

Common constraints:
- ...

Unique strengths:
- peerA: ...
- peerB: ...

Repeated pain points:
- ...

Reusable workflows worth saving:
- ...

Recommendations for all peers:
- ...

Questions for round N+1:
- ...

Persistence decision:
- memory: ...
- skills: ...
- session files only: ...
```

## Feedback prompt to peers

```text
Here is the round-N synthesis from the Hermes peer mesh.
Please review it, say which recommendations apply to you, correct anything inaccurate about your report, and add one additional operational lesson if you have one.
Do not reveal secrets, private user content, raw env dumps, credentials, or sensitive personal data.
```

## Session-specific note from the originating conversation

A peer at `192.168.178.128:8642` responded successfully to `/health` but returned `Invalid API key` on `/v1/capabilities`. The durable lesson is not that the peer is broken; it is the verification ladder: health proves reachability, capabilities proves authenticated mesh configuration.
