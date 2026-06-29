# Raspberry Pi Hermes Peer Setup

Covers Hermes Agent on Raspberry Pi (aarch64, Debian bullseye). These nodes are thermally unconstrained, low-power, and suitable for always-on bridge/gateway roles.

## Reference topology (peer70)

| Attribute | Value |
|---|---|
| Model | Raspberry Pi (3.7 GB RAM, 59 GB SD) |
| OS | Debian 11 bullseye, kernel 5.15.61-v8+, aarch64 |
| Hostname | raspberrypi (also raspberrypi.fritz.box) |
| LAN IP | 192.168.178.70 |
| SSH user | fausto (key auth, ~/.ssh/id_rsa) |
| Hermes | v0.17.0, binary at ~/.local/bin/hermes (not in default PATH) |
| Provider | Nous Portal (deepseek/deepseek-v4-flash) |
| Gateway | Telegram connected, PID tracked in gateway_state.json |
| API server | Port 8642, Bearer auth |
| Role | 24/7 bridge to outside world, daytime lightweight work |

## Hermes binary not in PATH

On Debian bullseye, ~/.local/bin/ is NOT in the default $PATH. Run Hermes commands via:

```bash
export PATH=$PATH:/home/fausto/.local/bin
hermes --version
```

Or use the absolute path: /home/fausto/.local/bin/hermes

## Gateway lifecycle

The gateway may already be running when you first SSH in — check gateway_state.json:

```bash
cat ~/.hermes/gateway_state.json
# → {"pid": 1542, "gateway_state": "running", "platforms": {"telegram": {"state": "connected"}}}
```

No systemd unit — the gateway is started manually or via a startup script.

## No firewalld / ufw

Raspberry Pi default install has no firewalld or ufw. Port 8642 is accessible from LAN without extra config. Verify with:

```bash
ss -tlnp | grep 8642
```

## Config structure

Same layout as other Hermes instances (~/.hermes/config.yaml, gateway_state.json, peer-network/, auth.json, logs/). Key differences from a laptop/orchestrator:
- No api_server section initially — must be added if not present
- Gateway uses use_gateway: true for all feature backends
- All backends go through the Nous Portal gateway (not local API keys)

## Enabling the API server

If the peer lacks an api_server section, add to config.yaml:

```yaml
gateway:
  platforms:
    api_server:
      extra:
        host: 0.0.0.0
        port: 8642
        key: "<your-api-key>"
```

Or set the key env var: `export API_SERVER_KEY="<hex-key>"` and add to ~/.profile.

**⚠️ Important**: If you use `hermes config set` to add the key, pass the FULL value — not an abbreviation with `...` in the middle. The tool stores the literal string as-is; `"f28d8a...58"` saves exactly that truncated text, not the intended 64-char key.

Then restart the gateway: `kill -TERM $(pgrep -f "gateway run")` (auto-restarts if supervisor-managed). The `hermes gateway restart` command is refused from inside the gateway process.

## Bidirectional mesh setup

After enabling the API server on the RPi, it needs its own `peer-mesh.yaml` so it can call back to the orchestrator and other peers:

```bash
# Create peer-mesh.yaml on the RPi
ssh fausto@<rpi-ip> "cat > ~/.hermes/peer-mesh.yaml << 'EOF'
peers:
  n56vv:
    url: http://192.168.178.84:8642
    api_key_env: HERMES_PEER_N56VV_KEY
    role: worker
    capabilities:
    - hermes
    - lan
    timeout: 300
  peer128:
    url: http://192.168.178.128:8642
    api_key_env: HERMES_PEER_128_KEY
    role: worker
    capabilities:
    - hermes
    - lan
    timeout: 300
EOF"
```

Save peer API keys in the RPi's `~/.profile`:
```bash
ssh fausto@<rpi-ip> "echo 'export HERMES_PEER_N56VV_KEY=\"<key>\"' >> ~/.profile"
ssh fausto@<rpi-ip> "echo 'export HERMES_PEER_128_KEY=\"<key>\"' >> ~/.profile"
```

Also add the keys to the MCP server's env in config.yaml on the RPi (this is where the MCP server actually reads them from — ~/.profile is only for interactive shells):
```bash
ssh fausto@<rpi-ip> "hermes config set mcp_servers.hermes_peers.env.HERMES_PEER_N56VV_KEY <key>"
ssh fausto@<rpi-ip> "hermes config set mcp_servers.hermes_peers.env.HERMES_PEER_128_KEY <key>"
```

**⚠️ MCP server restart = session disruption**: After adding/updating env vars in the MCP server config, killing the MCP process breaks the current Hermes session's MCP client connection. The gateway respawns the server, but the client auto-retries with backoff (3s → 22s → 56s). This is normal — wait for the retry or use direct curl to verify the peer in the meantime.

## Typical capabilities on RPi

Responses API, Runs API (async task submission), Sessions API (create/chat/fork), Skills API, streaming, run status/events/stop.

## Daytime workload pattern

Since the RPi has no thermal constraints:
- Handles lightweight 24/7 tasks (web scraping, API polling, Telegram bridge)
- Takes over during orchestrator cooling windows
- Never needs cooling windows or resource throttling
- Can run cron jobs and faro-health monitoring uninterrupted
