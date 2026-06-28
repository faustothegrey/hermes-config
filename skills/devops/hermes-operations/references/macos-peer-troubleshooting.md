# macOS Peer Troubleshooting

Common failure mode: the peer passes ping but the Hermes `/health` endpoint
times out, alternating between quick responses and long timeouts.

## Root cause chain

1. macOS accumulates background processes that don't naturally throttle.
2. Agent-bus (launchd KeepAlive) respawns CPU-hungry sub-agents (e.g. `agy`)
   immediately after they are killed.
3. Time Machine starts massive backups (300+ GB) that run for days.
4. SystemUIServer, Airportd, WindowServer, WallpaperAerialsExtension can all
   spin at 20-100 % CPU after several days of uptime.
5. Result: load averages of 15-20 cripple Hermes responsiveness even though the
   process stays up on port 8642.

## Diagnostic commands (SSH as local user, NOT root)

```bash
# Overall load
uptime

# CPU hogs, desc
ps aux | sort -nrk 3 | head -10

# Check if Hermes is listening
lsof -iTCP:8642 -sTCP:LISTEN -P -n

# Time Machine status
tmutil currentphase         # Idle | Copying | Stopping
tmutil status               # JSON: percent, time remaining, files
tmutil destinationinfo      # Volume, mount point

# Agent-bus / persistent service detection
launchctl list | grep -iE "agent.bus|tirith|hermes"
ls ~/Library/LaunchAgents/ | grep -iE "agent.bus|tirith|hermes"
```

## Fixes

### Kill runaway non-respawning processes
```bash
pkill -f "ProcessName"     # e.g. agy, Activity Monitor, SystemUIServer
```
SystemUIServer, WindowServer, and airportd are restarted by launchd; killing
them gives a clean restart that usually fixes the spin.

### Stop processes that respawn (agent-bus pattern)
If `pkill -f agy` works but agy comes back, it is managed by a LaunchAgent
with `KeepAlive=true`.

1. Identify the plist: `ls ~/Library/LaunchAgents/`
2. Unload it: `launchctl unload ~/Library/LaunchAgents/com.fausto.agent-bus.plist`
   (or `launchctl bootout gui/$(id -u)/com.fausto.agent-bus` on recent macOS)
3. Rename to prevent reload at next login:
   `mv ~/Library/LaunchAgents/com.fausto.agent-bus.plist{,.disabled}`
4. Kill lingering children: `pkill -f "agent-bus/server.py"`

### Pause Time Machine (no sudo)
```bash
tmutil stopbackup
```
This works without sudo. The backup stays paused until macOS decides to resume
it (minutes to hours later). For permanent disable, user must run
`sudo tmutil disable` from the console.

### SSH key setup (Linux → macOS)
- macOS SSH user is the account name (e.g. `fausto`), NOT `root`.
- Append public key to `~/.ssh/authorized_keys` on the Mac:
  ```bash
  ssh <user>@<ip> "echo '<pubkey>' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  ```
- Verify: `ssh -o BatchMode=yes <user>@<ip> "hostname"`

## Preemptive actions for the user
- Disable animated wallpapers (WallpaperAerialsExtension).
- Reboot the Mac periodically (uptime >3-4 days often shows runaway daemons).
- Run `sudo tmutil disable` from the console if Time Machine backups are
  unnecessary or misconfigured.
- Remove `agy` sessions from agent-bus config if they are not needed.
