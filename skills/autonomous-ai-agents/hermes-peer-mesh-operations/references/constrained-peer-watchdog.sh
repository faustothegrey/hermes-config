#!/bin/bash
# ============================================================
# constrained-peer-watchdog.sh — template for resource-limited Hermes peers
#
# Deploy with:
#   1. Copy to ~/.hermes/scripts/watchdog.sh, chmod +x
#   2. Create systemd oneshot service + timer (see below)
#   3. systemctl --user enable --now hermes-watchdog.timer
#
# Design constraints:
#   - Pure bash, no Python, no extra memory
#   - Cooldown via lock file mtime (not system clock — SBC RTCs lie)
#   - Logs to ~/.hermes/watchdog.log
# ============================================================
set -euo pipefail

API_URL="${HERMES_WATCHDOG_URL:-http://127.0.0.1:8642}"
LOCK_FILE="${HERMES_WATCHDOG_LOCK:-/tmp/hermes-watchdog.lock}"
LOG_FILE="${HERMES_WATCHDOG_LOG:-$HOME/.hermes/watchdog.log}"
COOLDOWN_SEC="${HERMES_WATCHDOG_COOLDOWN:-900}"   # 15 min
HEALTH_TIMEOUT="${HERMES_WATCHDOG_TIMEOUT:-10}"    # curl timeout
SERVICE_NAME="${HERMES_WATCHDOG_SERVICE:-hermes-gateway}"

log() { echo "[$(date -Iseconds)] $*" >> "$LOG_FILE"; }

# ── Health check ──────────────────────────────────────────
if curl -sf --max-time "$HEALTH_TIMEOUT" "$API_URL/health" > /dev/null 2>&1; then
    log "OK health=up"
    exit 0
fi

# ── Gateway unreachable ───────────────────────────────────
log "ERROR health=down"

now=$(date +%s)
last_restart=0
[ -f "$LOCK_FILE" ] && last_restart=$(stat -c %Y "$LOCK_FILE" 2>/dev/null) || true

if [ $((now - last_restart)) -lt $COOLDOWN_SEC ]; then
    remaining=$(( (COOLDOWN_SEC - (now - last_restart)) / 60 ))
    log "SKIP restart — cooldown active (${remaining}m remaining)"
    exit 0
fi

# ── Restart ───────────────────────────────────────────────
log "ACTION restarting $SERVICE_NAME"
touch "$LOCK_FILE"
systemctl --user restart "$SERVICE_NAME" 2>&1 | while IFS= read -r line; do
    log "restart: $line"
done

sleep 3

if curl -sf --max-time "$HEALTH_TIMEOUT" "$API_URL/health" > /dev/null 2>&1; then
    log "OK restart succeeded — health=up"
else
    log "WARN restart completed but /health still unreachable after 3s"
fi

# ── Systemd unit templates ────────────────────────────────
# Service (~/.config/systemd/user/hermes-watchdog.service):
#   [Unit]
#   Description=Hermes Watchdog
#   [Service]
#   Type=oneshot
#   ExecStart=%h/.hermes/scripts/watchdog.sh
#
# Timer (~/.config/systemd/user/hermes-watchdog.timer):
#   [Unit]
#   Description=Hermes Watchdog Timer
#   [Timer]
#   OnCalendar=*:0/10
#   Persistent=true
#   [Install]
#   WantedBy=timers.target
