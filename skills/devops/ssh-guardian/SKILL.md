---
name: ssh-guardian
description: "Temporary SSH access via messaging-platform-authenticated firewall: open a secondary SSH port on demand through Telegram (or any Hermes-connected channel), with auto-timeout and keepalive. Zero persistent exposure."
version: 1.0.0
author: Hermes Agent
tags: [ssh, security, firewall, telegram, port-knocking, iptables, access-control]
---

# SSH Guardian — Temporary Port Access via Messaging Channel

Alternative to port knocking, VPN, or permanent port forwarding. Uses an authenticated messaging channel (Telegram, Discord, etc.) as the side channel to temporarily open a firewall rule for SSH.

## Architecture

```
                       ┌─────────────────────────────────┐
User ──Telegram──→ Hermes Agent ──→ guardiano.sh open     │
  "apri 2222"          (this session)  │                  │
                                       ▼                  │
                               ┌──────────────┐           │
                               │  iptables     │          │
                               │  ACCEPT :2222 │          │
                               │  (sovra DROP) │          │
                               └──────┬───────┘           │
                                      │                   │
                         cron */2 ────┤                   │
                         guardiano-   │                   │
                         watchdog.sh  │                   │
                                      ▼                   │
                              Timer check & close ────────┘
```

**Key insight:** The router port-forward points to :2222 permanently. iptables on the host blocks it by default (DROP rule). The agent adds an ACCEPT rule in front only when the user requests it via the messaging channel — which is already authenticated (Telegram user ID, etc.).

## Components

### 1. `guardiano.sh` — State machine
- `open` — adds iptables ACCEPT rule for :2222, writes state file, starts 20-min timer
- `close` — removes ACCEPT rule, clears state, sends notification
- `keepalive` — touches `/tmp/guardiano-keepalive` flag (watchdog picks it up)
- `status` — reads state file, reports open/closed + time remaining
- `watchdog` — main logic: checks timer, warns at 2-min mark, closes on expiry, processes keepalive flag

### 2. `guardiano-watchdog.sh` — Cron entry point
- Runs `guardiano.sh watchdog` every 2 min
- Pipes important events (warnings, timeouts, keepalive resets) through `hermes send --to telegram`
- Silent when nothing to report

### 3. Cron jobs
```
*/2 * * * * ~/.hermes/scripts/guardiano-watchdog.sh > /dev/null 2>&1
```
Replaces `@reboot` for any SSH port control cron.

### 4. SSH config
```
Port 22
Port 2222
```
sshd listens on both; iptables blocks :2222 at the network level.

## Installation on a new machine

```bash
# 1. SSH config — add second port
sudo sed -i 's/^#\?Port 22/Port 22\nPort 2222/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 2. iptables default DROP
sudo iptables -A INPUT -p tcp --dport 2222 -j DROP

# 3. Make iptables rule persistent (distribution-dependent)
# Debian/Ubuntu: sudo apt install iptables-persistent
# Fedora/RHEL:   sudo dnf install iptables-services
# Or write a @reboot cron: sudo iptables -A INPUT -p tcp --dport 2222 -j DROP

# 4. Copy scripts
cp guardiano.sh ~/.hermes/scripts/
cp guardiano-watchdog.sh ~/.hermes/scripts/
chmod +x ~/.hermes/scripts/guardiano.sh ~/.hermes/scripts/guardiano-watchdog.sh

# 5. Cron
(crontab -l 2>/dev/null; echo '*/2 * * * * ~/.hermes/scripts/guardiano-watchdog.sh > /dev/null 2>&1') | crontab -
```

## User-facing commands

The agent recognizes these when the user says them in any Hermes channel:

| User says | Action |
|-----------|--------|
| "apri 2222" / "apri SSH" | `guardiano.sh open` |
| "chiudi 2222" / "chiudi SSH" | `guardiano.sh close` |
| "la porta?" / "com'è la porta?" | `guardiano.sh status` |
| "sì" / "tieni aperto" (after warning) | `guardiano.sh keepalive` |

The agent should:
1. Execute the script
2. Report back the result to the user
3. If opening: tell the user the expiry time
4. For "sì" responses: check if guardiano state exists before applying keepalive

## Timing defaults

| Event | Time | Trigger |
|-------|------|---------|
| Port opens | t+0 | User command |
| Telegram warning | t+18min | "⏳ scade tra 2 min, rispondi sì" |
| Keepalive accepted | any | User "sì" → resets to t+20min |
| Port closes | t+20min | Silent expiry; Telegram "🔒 chiusa" |
| Manual close | any | User "chiudi" |

## Pitfalls

- **`hermes send` requires a running Hermes session** — the gateway platform credentials must be configured. If the gateway is down, Telegram warnings silently fail. The watchdog still closes the port on timeout regardless.
- **iptables rules are ephemeral** — a reboot clears them unless saved or added via `@reboot`. The DROP rule MUST be persistent or re-added at boot.
- **Keepalive race condition** — if the user says "sì" between two watchdog ticks, the flag sits until the next tick (max 2 min delay). This is intentional: the port stays open during that window, it just doesn't extend the timer until the flag is processed.
- **Multiple simultaneous openings** — the state machine is single-instance. A second `open` while one is active just refreshes the timer. If you need concurrent access, manage separate chains.
- **Router port forwarding** must already point to :2222. This tool does not configure the router.
- **Logging** — all state lives in `/tmp/` files and `/tmp/guardiano.log`. Logs survive reboot only if you move them to `~/.hermes/peer-status/` or similar.

## Deployment history

This system was originally authored as `guardiano-ssh` (Italian-named skill)
before consolidation. The Italian deployment perspective and specific LAN
configuration are preserved in
`references/guardiano-deployment-history.md` — load it when working with
the original Italian commands or debugging the specific LAN deployment
at 192.168.178.84:2222.

Key Italian user commands still supported:

| User says | Action |
|-----------|--------|
| "apri 2222" / "apri SSH" | `guardiano.sh open` |
| "chiudi 2222" / "chiudi SSH" | `guardiano.sh close` |
| "la porta?" / "com'è la porta?" | `guardiano.sh status` |
| "sì" / "tieni aperto" (after warning) | `guardiano.sh keepalive` |

## Related patterns

- **Faro beacon protocol** (`faro-peer-beacon` skill) — passive peer uptime monitoring, complementary to guardiano (monitor status, don't control access).
- **Port knocking** — alternative pattern that uses a sequence of connection attempts instead of a messaging channel. Less reliable (packet loss breaks the sequence, no user feedback).
- **Tailscale/WireGuard** — full VPN overlay. More complex setup but provides always-on encrypted access instead of temporary port opening.