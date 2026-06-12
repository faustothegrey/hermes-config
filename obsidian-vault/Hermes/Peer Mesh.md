# Hermes Peer Mesh

Updated: 2026-06-12T16:24:31+02:00

## Purpose

Operational notes for the local Hermes-to-Hermes peer setup. The permanent Hermes memory should keep only a compact pointer to this note and the essential paths.

## Architecture chosen

Current implementation is option 3: a central MCP wrapper on this orchestrator machine calls remote Hermes peers through their API Server.

This is intentionally structured so option 2 can reuse most of the work later: install the same wrapper/client on every peer, enable inbound API Server on every peer, and give each peer a peer config.

## Local orchestrator paths

- MCP wrapper directory: `/home/fausto/.hermes/mcp/hermes-peers`
- MCP server name in Hermes config: `hermes_peers`
- Peer config file: `/home/fausto/.hermes/peer-mesh.yaml`
- Hermes env file for peer API keys: `/home/fausto/.hermes/.env`
- Hermes config file: `/home/fausto/.hermes/config.yaml`

## Wrapper structure

- `peer_config.py`
  - Loads `~/.hermes/peer-mesh.yaml`.
  - Resolves `api_key_env` from environment, with fallback to `~/.hermes/.env` because MCP subprocesses may receive a filtered environment.

- `hermes_peer_client.py`
  - Reusable Hermes API client.
  - This is the part to reuse for a future full mesh/native plugin.

- `server.py`
  - MCP-specific wrapper around the reusable client.

## MCP tools exposed

The MCP server exposes these tools:

- `list_peers`
- `peer_health`
- `peer_capabilities`
- `call_peer`
- `start_peer_run`
- `get_peer_run`
- `get_peer_events`
- `stop_peer_run`

In Hermes they appear with the MCP server prefix, e.g. `mcp_hermes_peers_*` depending on the active tool registry naming.

## Local API Server

The local machine has Hermes gateway running as a user systemd service with linger enabled.

API Server was enabled on all interfaces:

```env
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
API_SERVER_KEY=<stored in ~/.hermes/.env; do not copy into notes>
```

Verified on 2026-06-12:

- `ss -ltnp` showed `LISTEN 0.0.0.0:8642` for the Hermes process.
- `http://127.0.0.1:8642/health` returned OK.
- `http://192.168.178.84:8642/health` returned OK.

## Peer 105

Peer name in config: `peer105`

Network:

- URL: `http://192.168.178.105:8642`
- Key env var on orchestrator: `HERMES_PEER_105_KEY`
- Key is stored in `/home/fausto/.hermes/.env`; do not store it in Obsidian.

Config shape in `/home/fausto/.hermes/peer-mesh.yaml`:

```yaml
peers:
  peer105:
    url: http://192.168.178.105:8642
    api_key_env: HERMES_PEER_105_KEY
    role: worker
    capabilities:
      - hermes
      - lan
    timeout: 300
```

Connectivity history:

- Initial TCP connection to `192.168.178.105:8642` failed because the peer was firewalled.
- ICMP ping worked: 0% packet loss, around 2.4 ms average RTT.
- After firewall adjustment, `/health` returned OK.
- `/v1/capabilities` without API key returned 401 Invalid API key, confirming auth enforcement.
- With the API key configured, `/v1/capabilities` returned HTTP 200 with `hermes.api_server.capabilities` and 21 endpoints.

## Peer 105 operational status

Asked via `call_peer` on 2026-06-12. The agent reported:

Status: `working`

Host/IP:

- `localhost.localdomain`
- `192.168.178.105`
- `fd00::ded2:cfec:ff76:2d3a`

Gateway/API:

- Gateway is active under systemd user service.
- API server listens on `0.0.0.0:8642`.
- `/health` returns 200 OK.
- Auth-protected endpoints reject missing/invalid API keys as expected.

Model/provider:

- `gpt-5.5`
- OpenAI Codex auth is logged in.

Limitations on peer105:

- Browser / browser-cdp / computer_use are hidden because Playwright Chromium is not installed.
- Web search unavailable: missing web/search API keys.
- Telegram and most messaging platforms are not configured.
- `~/.local/bin/hermes` symlink missing, so `hermes` may not work outside the venv.
- `ripgrep` (`rg`) missing; file search falls back to slower grep.
- No OpenRouter/OpenAI/Google/etc. API keys configured besides OpenAI Codex auth.

Suggested fixes for peer105:

- Run `hermes doctor --fix` for the missing CLI symlink.
- Install Playwright Chromium if browser tools are needed.
- Configure API keys/platform tokens if web search or messaging platforms should work.
- Install `ripgrep` if faster search is desired.

## Verification commands used locally

```bash
hermes mcp test hermes_peers
PYTHONPATH=/home/fausto/.hermes/mcp/hermes-peers \
  /home/fausto/.hermes/hermes-agent/venv/bin/python - <<'PY'
import hermes_peer_client as c
print(c.list_peers())
print(c.health('peer105'))
print(c.capabilities('peer105'))
PY
```

## Future option 2 notes

To evolve from option 3 to option 2/full mesh:

1. Install/copy the same wrapper/client package on every peer.
2. Enable inbound Hermes API Server on every peer.
3. Put each peer's API key in the local `.env` of machines allowed to call it.
4. Replicate or generate a peer-specific `peer-mesh.yaml` on every peer.
5. Reuse `hermes_peer_client.py` as the stable transport layer.
6. Optionally convert `server.py` into a native Hermes plugin/tool wrapper later.

Keep secrets only in `.env`, never in Obsidian.
