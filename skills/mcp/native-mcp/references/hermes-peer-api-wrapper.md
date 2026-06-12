# Hermes peer API wrapper pattern

Use this when a user wants multiple Hermes instances on different LAN machines to communicate through an API model.

## Finding from 2026-06 session

A repo/docs check found no ready-made bundled plugin named agent-to-agent, federation, peer, or remote-Hermes worker. The native pieces that exist are:

- Hermes API Server: exposes each Hermes instance over HTTP, including OpenAI-compatible endpoints and run/session endpoints.
- Native MCP client: lets an orchestrator Hermes consume MCP servers as first-class tools.
- Gateway/event hooks: useful for lifecycle notifications, not a full peer bus.
- Messaging platform plugins: useful as human-visible buses, but not a pure API peer model.

## Recommended architecture

For LAN worker nodes, prefer a thin MCP server wrapper around each worker's Hermes API Server rather than teaching the model to hand-write curl calls.

Worker Hermes instance:

```env
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
API_SERVER_KEY=<redacted-long-random-key>
```

Start/restart the worker gateway normally, then verify health and capabilities from the orchestrator host.

Orchestrator Hermes:

```yaml
mcp_servers:
  hermes_peers:
    command: "/path/to/hermes/venv/bin/python"
    args: ["/path/to/hermes-peers/server.py"]
    env:
      HERMES_PEER_MESH_CONFIG: "/home/user/.hermes/peer-mesh.yaml"
    timeout: 300
    connect_timeout: 30
```

Peer registry example:

```yaml
# ~/.hermes/peer-mesh.yaml
peers:
  peer105:
    url: http://192.168.178.105:8642
    api_key_env: HERMES_PEER_105_KEY
    role: worker
    capabilities: [hermes, lan]
    timeout: 300
```

Store `HERMES_PEER_105_KEY` in `~/.hermes/.env` or pass it explicitly in the MCP server's `env` block. Do not hardcode live API keys in `peer-mesh.yaml` unless the user explicitly accepts that tradeoff.

## Reusable implementation shape

Keep the wrapper split so this option-3 central orchestrator can evolve into option-2 peer-to-peer mesh later:

- `peer_config.py` — loads `peer-mesh.yaml`, returns redacted peer metadata, resolves `api_key_env`.
- `hermes_peer_client.py` — reusable API client for `/health`, `/v1/capabilities`, `/v1/responses`, `/v1/runs`, run status/events/stop.
- `server.py` — MCP-only wrapper that exposes client functions as tools.

The wrapper should expose stable tool names such as:

- `list_peers` — show configured workers, URLs, health, and capabilities.
- `peer_health` — probe `/health` or `/health/detailed`.
- `peer_capabilities` — authenticated `/v1/capabilities` check.
- `call_peer` — synchronous short prompt via `/v1/responses`.
- `start_peer_run` — long-running task via `/v1/runs`.
- `get_peer_run` — status/result for a run.
- `get_peer_events` — inspect bounded SSE run events.
- `stop_peer_run` — cancel a remote run.

## Verification recipe

From the orchestrator, before adding a peer key:

```bash
ping -c 4 <peer-ip>
curl -fsS --max-time 5 http://<peer-ip>:8642/health
curl -sS --max-time 5 -w '\nHTTP_STATUS:%{http_code}\n' http://<peer-ip>:8642/v1/capabilities
```

After adding the key, ask the peer a small operational-status question through `call_peer` or `/v1/responses` and require a compact structured answer (`working` / `not working`, gateway/API state, provider auth, missing major toolsets). `/v1/responses` may return a full response object containing tool-call items before the final message; extract the final `output_text`/message content rather than dumping the entire object to the user.

Expected:

- `/health` returns JSON without a key.
- `/v1/capabilities` returns `401 Invalid API key` without a key; that proves auth is active.
- With the key, `/v1/capabilities` returns HTTP 200 and object `hermes.api_server.capabilities`.

On the peer, verify the bind address:

```bash
ss -ltnp | grep :8642
```

Expected LAN worker bind:

```text
LISTEN ... 0.0.0.0:8642 ... hermes
```

If ping works but TCP to 8642 fails, check the peer firewall before debugging Hermes.

## Pitfalls

- Do not claim a ready-made Hermes-to-Hermes federation plugin exists unless confirmed in the current install or docs.
- Redact all API keys and bearer tokens in notes and user-facing output.
- For LAN exposure, avoid leaving unauthenticated API servers bound to `0.0.0.0`; Hermes API Server refuses to start without `API_SERVER_KEY` in newer builds.
- Prefer `/v1/runs` for long jobs; use `/v1/responses` only for short calls.
- Hooks are useful for notifications, but they do not replace a status/result API.
- `hermes mcp add` may connect and then prompt interactively to enable discovered tools; if unattended it can cancel without writing config. For automation, write `mcp_servers` directly or run the command interactively and answer the prompt.
- MCP subprocesses inherit a filtered environment. Secrets in `~/.hermes/.env` may not appear as process environment variables unless passed via `mcp_servers.<name>.env`; wrappers can also implement a deliberate `.env` lookup for `api_key_env`.
