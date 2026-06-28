# macOS Peer Diagnosis

Covers Hermes peers running on macOS via the Agent Bus (Tirith) architecture. These peers behave differently from Linux peers — different SSH user, different install layout, and timeout patterns under high load.

## SSH access

- **Username**: macOS short name (not `root`). On this mesh: `fausto@192.168.178.128`.
- **Key auth**: works with the same `~/.ssh/id_rsa` used for Linux peers — but only if `ssh-copy-id` was run with the macOS user, not `root`.
- **Shell**: macOS uses `zsh` by default. Commands work as-is.

## Hermes install layout (Agent Bus / Tirith)

Hermes on macOS was installed via **git** (not pip/uv). Key differences:

| Aspect | Linux (pip/uv) | macOS (Agent Bus) |
|---|---|---|
| Binary location | `~/.local/bin/hermes` | `~/.hermes/bin/tirith` |
| PATH availability | yes (symlinked) | **not in PATH** — `hermes` command not found |
| Service model | gateway systemd | Agent Bus services (agent-bus, quota-api, agent-telemetry) |
| Config | `~/.hermes/config.yaml` | same `~/.hermes/config.yaml` |
| Service monitor | systemctl | `~/.hermes/service-monitor-state.json` |

### Verifying services

Check the service monitor JSON:
```bash
cat ~/.hermes/service-monitor-state.json
```

Expected output shows Agent Bus components:
```json
{
  "agent-bus": { "status": "up", "detail": "HTTP 200" },
  "quota-api": { "status": "up", ... },
  "agent-telemetry": { "status": "up", ... }
}
```

The `tirith` process may not appear in `ps aux` even when services are up (Agent Bus daemon manages them).

## Peer API server

Even with Agent Bus, the Hermes API server **is** present and listens on port 8642:

```bash
lsof -iTCP -sTCP:LISTEN -P -n | grep 8642
# → python3.1  PID  fausto  24u  IPv4 ...  TCP *:8642 (LISTEN)
```

PID belongs to a Python process (the Hermes API server).

## High-load timeout pattern vs "frozen but alive" (SSH-wakeup)

Two distinct failure modes with identical symptoms (health timeout) but different root causes and resolution.

### High-load timeout pattern

macOS peers under sustained high load may fail health checks even when the service is running correctly.

**Symptoms:**
- `mcp_hermes_peers_list_peers(include_health=true)` → peer shows `timeout` or `error`
- `ping` to the peer succeeds
- Port 8642 is open via `nc -zv`
- `lsof` confirms the process is listening
- SSH works fine
- A **second health check** succeeds moments later

**Root cause**: The peer is under extreme load (load average 20+), and the health check's timeout expires before the peer can respond. Common culprits on a MacBook:
- `agy` process spinning at 99.9% CPU (Agent Bus worker / Google agent spawned by agent-bus)
- `opendirectoryd` at 100%+ (macOS directory service — often a kernel bug or misconfiguration)
- Time Machine (`backupd`) during a backup — can reach 50-98% CPU
- `airportd` at 70%+ (Wi-Fi daemon gone rogue — very abnormal)
- `SystemUIServer` at 50%+ (menu bar/notification daemon — normally <1%)
- Multiple `wrapper.sh` agent-bus sessions
- IDEs (Antigravity, Codex) + multiple language servers
- WallpaperAerialsExtension (animated wallpaper/screensaver — can consume 20%+)

**Diagnosis checklist** (when health check times out but peer shouldn't be down):

1. **Ping the peer** — network reachability
   ```bash
   ping -c 4 <peer-ip>
   ```

2. **Check port 8642** — is the Hermes API listening?
   ```bash
   nc -zv -w3 <peer-ip> 8642
   ```

3. **Check SSH + processes** — is the service alive?
   ```bash
   ssh user@<peer-ip> "lsof -iTCP -sTCP:LISTEN -P -n | grep 8642"
   ssh user@<peer-ip> "cat ~/.hermes/service-monitor-state.json"
   ```

4. **Check load** — is the machine overwhelmed?
   ```bash
   ssh user@<peer-ip> uptime
   # load averages: 20.03 12.64 12.92 ← extremely high for a MacBook
   ```

5. **Retry health check** — once load settles, the endpoint responds normally
   ```bash
   mcp_hermes_peers_peer_health(peer="peer128")
   ```

**When to call it truly down (vs timeout):**
- Ping fails → network issue or machine asleep
- Port 8642 is closed → service not running
- SSH fails → could be sleep/hibernate

**When to retry:**
- Ping OK + port 8642 open + SSH works → just high load → retry the MCP health check

### "Frozen but alive" pattern (SSH-wakeup)

A distinct failure mode where the peer appears dead from the orchestrator but immediately revives when SSH'd into. The user-visible symptom is systematic: *"Si sveglia quando fai l'accesso tu via SSH"* — the peer only responds after the orchestrator checks on it.

**Symptom set (all at once):**
- Health check from orchestrator → timeout (`<urlopen error timed out>`)
- Ping → ✅ OK (100% packet loss, no reply until SSH)
- Port 8642 check (`nc -zv`) → ❌ timeout
- SSH → ✅ connects immediately
- After SSH connects → health check from orchestrator → ✅ works again
- After ~2-5 minutes of inactivity → returns to frozen state

**Root cause:** macOS suspends the Hermes Python process via **App Nap** (or equivalent network-level suspension) after a period of inactivity — even when `pmset -g` reports "sleep prevented by powerd." The process's network stack stops accepting new TCP connections to non-privileged ports (above 1024). SSH (port 22) is treated differently by macOS and successfully wakes the full network stack, allowing port 8642 to accept connections again.

**Diagnosis checklist:**

1. From orchestrator: `curl -s --connect-timeout 5 http://<peer-ip>:8642/health` → timeout
2. From orchestrator: `ping -c 2 <peer-ip>` → no reply (or very intermittent)
3. From orchestrator: `nc -zv -w3 <peer-ip> 8642` → timeout
4. SSH in: `ssh fausto@<peer-ip> uptime` → connects immediately (load may be normal)
5. On peer (via SSH): `curl -s http://localhost:8642/health` → ✅ 200 OK (process alive locally)
6. SSH out, then retry step 1 from orchestrator → ✅ works now

**Resolution: `ProcessType: Background` in launch agent plist.**

Edit `~/Library/LaunchAgents/ai.hermes.gateway.plist` to add:

```xml
<key>ProcessType</key>
<string>Background</string>
```

This tells launchd this is a background service process, exempting it from App Nap. See "App Nap prevention on macOS" section below for full procedure.

**Distinguishing from "High-load timeout" pattern:**

| Signal | High-load timeout | Frozen but alive (SSH-wakeup) |
|---|---|---|
| Load average | 15-20+ | Normal (1-5) |
| Port 8642 via SSH (`lsof`) | ✅ Open | ✅ Open |
| localhost health check | ✅ Responds (slow) | ✅ Responds (instant) |
| Remote health check after SSH | Works (load settled) | Works immediately |
| Sustained responsiveness | ✅ Stays responsive once load drops | ❌ Freezes again after 2-5 min of inactivity |
| SSH first-time-of-day | Works on first attempt | Works on first attempt |

## High-load process mitigation

When SSH access works and the Mac is clearly overloaded (load >15), you can safely kill certain processes to relieve pressure. **Always verify the process identity first with `ps aux | sort -nrk 3 | head -10`** before killing anything.

### Safe-to-kill processes (macOS auto-restarts or they're session-specific)

| Process | Typical CPU | Why it spikes | Kill command | Auto-restart? |
|---|---|---|---|---|
| `SystemUIServer` | 50%+ | Pathological — normally <1%. macOS menu bar/notifications daemon gone rogue. | `killall SystemUIServer` | ✅ macOS relaunches it cleanly |
| `Activity Monitor` | 20-25% | Running it to diagnose high load ironically consumes CPU itself | `killall "Activity Monitor"` | ❌ User must relaunch if needed |
| `agy` | 99.9% | Google Agent Bus spawned worker — can spin out of control | `pkill -f agy` | ❌ User relaunches via agent-bus if needed |
| `WallpaperAerialsExtension` | 20-25% | Animated wallpaper/screensaver | `killall WallpaperAerialsExtension` | ✅ macOS restarts when display wakes |

### Processes to NOT kill

| Process | Why |
|---|---|
| `backupd` (Time Machine) | Core macOS service — kills itself when backup finishes; killing may corrupt the backup |
| `opendirectoryd` | Core directory service — killing can break network auth |
| `WindowServer` | Window compositor — killing logs out the user |
| `iTerm2` / Terminal | User's active sessions |
| Antigravity IDE / Codex | User's active work |

### Process-level diagnosis protocol

1. Snapshot current load: `ssh user@<peer> uptime`
2. Identify top CPU consumers: `ssh user@<peer> "ps aux | sort -nrk 3 | head -6"`
3. For each suspicious process (≥20% CPU):
   - Check against safe-to-kill table above
   - Kill if safe, skip if not
4. After killing, re-check: `ssh user@<peer> uptime`
5. Verify Hermes responsiveness: `curl -s --connect-timeout 5 http://<peer-ip>:8642/health`

### Typical load trajectory after mitigation

Starting from load ~20 (5 days uptime, multiple runaway processes):
- Kill `agy` (99.9% CPU) → load drops from 20 → 15
- Kill `SystemUIServer` (52% CPU) → load drops from 16 → 14
- Kill `Activity Monitor` (23% CPU) → incremental relief
- Remaining load is usually `backupd` (Time Machine) at ~40-50% — finishes on its own
- End state: load settles to baseline (3-8 depending on Mac model and active apps)

## App Nap prevention on macOS

macOS App Nap can suspend the Hermes Python process even when the machine is "awake" (lid open, external display attached). The **user-visible symptom** is systematic: the peer's Telegram bot only responds when the orchestrator checks on it via SSH or curl ("si sveglia quando fai l'accesso tu via SSH").

### First-layer fix: ProcessType in launch agent plist

Edit the Hermes launch agent plist (`~/Library/LaunchAgents/ai.hermes.gateway.plist`) to add `<key>ProcessType</key><string>Background</string>`. This tells launchd this is a background service process, exempting it from App Nap:

```xml
<key>WorkingDirectory</key>
<string>/Users/fausto/.hermes/hermes-agent</string>

<key>ProcessType</key>
<string>Background</string>

<key>EnvironmentVariables</key>
```

Apply by reloading the agent:
```bash
launchctl unload ~/Library/LaunchAgents/ai.hermes.gateway.plist
sleep 2
launchctl load ~/Library/LaunchAgents/ai.hermes.gateway.plist
```

After reload, the process restarts. Verify with:
```bash
lsof -iTCP -sTCP:LISTEN -P -n | grep 8642
curl -s http://localhost:8642/health
```

**Observation:** Even with `ProcessType: Background`, the peer has been observed to freeze again after 2-5 minutes of inactivity. ProcessType helps but may not be sufficient on all macOS versions. See next section for the definitive fix.

### ⚠️ Ultimate fix: SSH tunnel from orchestrator (bypasses macOS network suspension)

When `ProcessType: Background` alone doesn't keep the peer responsive (the peer still freezes, and only SSH access revives it), the real root cause is **macOS suspending new incoming TCP connections to non-privileged ports (above 1024)** even when the system is "awake." SSH (port 22) is treated differently — it wakes the full network stack.

**The solution is to route all Hermes peer traffic through an SSH tunnel from the orchestrator.** This way:
- SSH handles the persistent connection (port 22 always works)
- macOS never suspends an active SSH session (ServerAliveInterval keeps it active)
- The tunnel forwards the orchestrator's local port to the Mac's localhost:8642
- All MCP peer checks, delegation, and cron jobs go through localhost instead of the remote IP

#### Step 1: Set up the persistent SSH tunnel

On the orchestrator machine, create a tunnel script at `~/.hermes/scripts/peer-tunnel.sh`:

```bash
#!/bin/bash
TUNNEL_PORT=18642
REMOTE_HOST=192.168.178.128
REMOTE_PORT=8642
SSH_USER=fausto

# Check if tunnel is already alive
if curl -sf --connect-timeout 3 http://127.0.0.1:$TUNNEL_PORT/health >/dev/null 2>&1; then
    exit 0
fi

# Kill any stale tunnel on this port
lsof -ti:$TUNNEL_PORT -sTCP:LISTEN 2>/dev/null | xargs kill 2>/dev/null || true
sleep 1

# Create new tunnel with keepalive
ssh -o ConnectTimeout=5 \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -o StrictHostKeyChecking=no \
    -L $TUNNEL_PORT:localhost:$REMOTE_PORT \
    -N -f $SSH_USER@$REMOTE_HOST 2>/dev/null

# Verify
if curl -sf --connect-timeout 3 http://127.0.0.1:$TUNNEL_PORT/health >/dev/null 2>&1; then
    echo "tunnel: OK"
else
    echo "tunnel: FAILED"
    exit 1
fi
```

Make it executable: `chmod +x ~/.hermes/scripts/peer-tunnel.sh`

#### Step 2: Set up a cron job to keep the tunnel alive

```yaml
# On the orchestrator (Hermes cron)
name: "<peer> Tunnel Keepalive"
schedule: "every 2m"
script: "peer-tunnel.sh"
no_agent: true
deliver: "local"
```

This checks every 2 minutes if the tunnel is alive, and recreates it if not. The SSH `ServerAliveInterval=15` keeps the session active between checks.

#### Step 3: Update the peer mesh config to use the tunnel

Edit `~/.hermes/peer-mesh.yaml`:

```yaml
  peer128:
    url: http://127.0.0.1:18642    # ← SSH tunnel, not direct IP
    api_key_env: HERMES_PEER_128_KEY
    role: worker
    capabilities:
    - hermes
    - lan
    timeout: 300
```

The MCP server reads peer-mesh.yaml dynamically — no restart needed. The next `mcp_hermes_peers_peer_health()` call goes through the tunnel.

#### Verification

```bash
# On orchestrator
curl -s --connect-timeout 5 http://127.0.0.1:18642/health
# → {"status": "ok", "platform": "hermes-agent"}

# MCP peer check (uses peer-mesh.yaml)
mcp_hermes_peers_list_peers(include_health=true)
# → peer128 url is now 127.0.0.1:18642
```

#### Notes

- Choose a local port (18642) that doesn't conflict with the orchestrator's own Hermes gateway (8642).
- The tunnel survives the Mac's network suspensions because SSH is treated as "existing traffic."
- If SSH key auth is not yet set up, configure it first (see "SSH key deployment" section).
- `ExitOnForwardFailure=yes` ensures the tunnel only stays up if the forward is established.

### Second-layer defense: Keepalive cron from orchestrator

A keepalive cron job provides defense-in-depth alongside the tunnel:

```yaml
name: "<peer> Keepalive"
schedule: "every 2m"
script: "curl -sf --connect-timeout 5 --max-time 8 http://127.0.0.1:18642/health >/dev/null 2>&1 && echo \"OK\" || echo \"DOWN\""
no_agent: true
deliver: "local"
```

This HTTP ping through the tunnel keeps both the tunnel and the peer's network stack active. Zero token cost (no_agent).

| Approach | Effectiveness | Complexity | Token cost |
|---|---|---|---|
| SSH tunnel (port forwarding) | 🔥 **Definitive** — bypasses macOS network suspension entirely | Medium (script + cron + mesh config) | Zero |
| `ProcessType: Background` in plist | ⚠️ Partial — helps but peer may still freeze | Low (edit plist + reload) | Zero |
| Keepalive cron (through tunnel) | ✅ Fallback — auto-repairs tunnel if it drops | Low (one cron create) | Zero (no_agent) |
| All three combined | 🛡️ Belt-and-suspenders | Medium | Zero |

**Recommendation:** Deploy all three. The SSH tunnel is the definitive fix; ProcessType helps on the Mac side; the keepalive cron ensures the tunnel stays up.

## Power management diagnostics via SSH

When a macOS peer appears unresponsive (health check times out), check power management settings first:

```bash
ssh fausto@<peer-ip> pmset -g
```

**Key fields to inspect:**

| Field | Normal | Problematic |
|---|---|---|
| `sleep` | 0 (disabled) | 1 (sleep enabled after 1 min) with "sleep prevented by powerd" |
| `displaysleep` | high or 0 | low (e.g. 10 min) |
| `powernap` | 0 | 1 (allows nap even while "awake") |
| `standby` | 0 | 1 (deep standby after delay) |
| `tcpkeepalive` | 1 | 0 |
| `acwake` | 1 | 0 (won't wake when plugged in — kills network service restarts) |

The `sleep 1 (sleep prevented by powerd, powerd, powerd)` state means something is *keeping* the Mac awake but user processes may still be subject to App Nap. If the peer is plugged in, consider suggesting the user run `sudo pmset -a sleep 0` at the keyboard.

## Time Machine management via SSH

Time Machine (`backupd`) is a common source of high CPU load on macOS peers. Manage without root:

| Action | Command | Requires sudo? |
|---|---|---|
| Check phase | `ssh fausto@<peer> tmutil currentphase` | No |
| Check progress | `ssh fausto@<peer> tmutil status` | No |
| Stop current backup | `ssh fausto@<peer> tmutil stopbackup` | No |
| Disable permanently | `sudo tmutil disable` | **Yes** — need keyboard or askpass |
| Check destination | `ssh fausto@<peer> tmutil destinationinfo` | No |

`tmutil status` returns JSON with `Percent`, `TimeRemaining`, `bytes`, `totalBytes`, and `files`/`totalFiles`. A 312 GB backup running at 33.5% for 6 days is abnormal — likely something went wrong.

When `tmutil disable` requires sudo but `tmutil stopbackup` succeeds, the backup will **restart automatically** after some time. The only permanent fix is the user running `sudo tmutil disable` at their keyboard, or configuring passwordless sudo: `echo 'fausto ALL=(ALL) NOPASSWD: /usr/sbin/tmutil' | sudo tee /etc/sudoers.d/tmutil`.

## Agent-bus disable procedure (LaunchAgents)

Agent-bus spawns `agy` workers that can consume 99.9% CPU. Disable via launchd:

```bash
# Find the agent-bus plist
ls ~/Library/LaunchAgents/ | grep -i "agent.bus\|agy\|tirith"

# Unload from current session
launchctl unload ~/Library/LaunchAgents/com.fausto.agent-bus.plist

# Prevent re-enable on next login (rename + remove)
mv ~/Library/LaunchAgents/com.fausto.agent-bus.plist ~/Library/LaunchAgents/com.fausto.agent-bus.plist.disabled

# Kill any remaining agy processes
pkill -f agy
pkill -f "agent-bus/server.py"

# To re-enable later:
# mv ~/Library/LaunchAgents/com.fausto.agent-bus.plist.disabled ~/Library/LaunchAgents/com.fausto.agent-bus.plist
# launchctl load ~/Library/LaunchAgents/com.fausto.agent-bus.plist
```

## SSH key deployment for macOS peers

Standard `ssh-copy-id` may not work if the Mac's SSH is already configured but the orchestrator's key hasn't been deployed. Alternative — deploy via inline command through the existing SSH session:

```bash
# Deploy public key from orchestrator to macOS peer
ssh-copy-id -i ~/.ssh/id_rsa.pub fausto@<peer-ip>
```

Or if `ssh-copy-id` isn't available or fails:

```bash
# Read the public key first
cat ~/.ssh/id_rsa.pub

# Then SSH in and append it
ssh fausto@<peer-ip> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
  echo 'ssh-rsa AAAA...' >> ~/.ssh/authorized_keys && \
  chmod 600 ~/.ssh/authorized_keys"

# Verify key-based auth works
ssh -o BatchMode=yes fausto@<peer-ip> "echo OK"
```

**Key detail:** macOS username is the short name (e.g. `fausto`), NOT `root`. The key goes in `/Users/fausto/.ssh/authorized_keys`, not `/root/.ssh/`.

## Gateway restart verification

When a user reports "I asked Hermes on the Mac to restart the gateway, but it didn't respond":

1. The MCP health check may time out, but this does NOT mean the gateway is down
2. SSH in and check if the PID actually changed:
   ```bash
   ps aux | grep -i hermes | grep -v grep
   # Compare PID with the one seen before the restart command
   ```
3. If the same PID is still running with unchanged `STARTED` time, the restart command didn't take effect
4. Check port 8642 directly:
   ```bash
   lsof -iTCP -sTCP:LISTEN -P -n | grep 8642
   ```
5. Direct curl from orchestrator (use a longer timeout — the Mac may be slow):
   ```bash
   curl -s --connect-timeout 10 --max-time 15 http://<peer-ip>:8642/health
   ```
6. If health returns 200, the peer was never down — it was just too slow to respond within the MCP tool's default timeout

### Transient Telegram connection timeout on gateway restart

When the Hermes launch agent plist is reloaded (unload + load), the new gateway process may encounter a transient Telegram connection timeout:

```
ERROR gateway.run: ✗ telegram error: telegram connect timed out after 30s
INFO  gateway.platforms.telegram: [Telegram] Disconnected from Telegram
```

**This is a transient issue**, not a permanent configuration error. The Mac's network stack may still be initializing, or the Telegram API server is slow to respond.

**Resolution:**
1. Kill the stuck process and let launchd auto-restart it:
   ```bash
   # Find the PID
   ps aux | grep "hermes_cli.main gateway" | grep -v grep
   # Kill it — launchd will restart automatically (KeepAlive=true)
   kill <PID>
   ```
2. Or use `launchctl kickstart -k` to force a fresh restart:
   ```bash
   launchctl kickstart -k gui/$(id -u)/ai.hermes.gateway
   ```
3. Wait 30-45 seconds for the new process to connect to Telegram
4. Verify: `curl -s http://localhost:8642/health` and check `tail -5 ~/.hermes/logs/gateway.log`

The second attempt almost always succeeds. Do NOT edit the plist or config — it's a transient network hiccup, not a configuration problem.

## Gateway restart side effects (sudo askpass cleanup)

When a peer's Hermes agent tries to execute sudo commands and creates an askpass script, the `diskutil verifyVolume` or similar commands can **hang indefinitely** on macOS due to Privacy & Security sandbox restrictions.

**Detection:** `ps aux` shows a `sudo -A diskutil verifyVolume disk3s2` process with an askpass wrapper in `/tmp/.hermes_safe/`. The shell script source will show the user's password written to a temp file.

**Remediation:**
1. Kill the stuck sudo + shell processes: `kill <sudo_pid> <shell_pid>`
2. **Critical:** Clean up the password from disk: `rm -rf /tmp/.hermes_safe/`
3. The Hermes gateway process continues running unaffected
4. Explain to the user: diskutil verifyVolume on macOS needs Full Disk Access permissions. It's a sandbox restriction, not a Hermes bug. Suggest the user either provides Full Disk Access to Terminal/iTerm2 in System Settings → Privacy & Security → Full Disk Access, or avoids running `diskutil` commands through Hermes.

## macOS full system reboot (osascript)

A quick reboot can resolve many of the above issues (runaway processes, stale daemons, load creep). The safest approach is to use `osascript` from SSH, which runs in the user's GUI session:

```bash
ssh fausto@<peer-ip> 'osascript -e "tell app \"System Events\" to restart"'
```

The Mac will initiate a graceful shutdown. After 2-3 minutes, it should be back up. The Hermes launch agent plist will auto-start the gateway on GUI login.
