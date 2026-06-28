# Faro — Peer Beacon Protocol — macOS Keepalive Note

## macOS needs higher-frequency polling

macOS peers (MacBook Pro) are subject to **App Nap** — the OS can suspend the Hermes process even when the machine appears awake (lid open, external display attached). The **beacon.sh** script running every 2 minutes from the peer side may not prevent this because the suspended process can't execute the cron job either.

**Solution:** Use a **bidirectional approach** for macOS peers:

1. **Peer→Orchestrator** (standard Faro push): `beacon.sh` every 2 minutes (as configured for peer128)
2. **Orchestrator→Peer** (keepalive pull): `no_agent=True` cron job pinging the Hermes health endpoint every 1-2 minutes

The pull from the orchestrator keeps the network stack active, preventing App Nap from freezing the process between beacons. On Linux peers (105, 106), the standard Faro beacon alone is sufficient because there's no App Nap.

### Keepalive cron job (orchestrator side)

```yaml
name: "peer128 Keepalive"
schedule: "every 1m"
script: "curl -sf --connect-timeout 5 --max-time 8 http://<peer-ip>:8642/health >/dev/null 2>&1 && echo \"OK\" || echo \"DOWN\""
no_agent: true
deliver: "local"
```

Zero token cost, zero resource impact. Creates a keepalive directory reference in `~/.hermes/peer-status/keepalive/` if tracking is needed.

For full details on App Nap prevention, see `hermes-peer-mesh-operations` skill's `references/macos-peer-diagnosis.md`.
