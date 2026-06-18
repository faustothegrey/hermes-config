#!/bin/bash
# ============================================================
# peer-watchdog.sh — Hermes peer resilience watchdog
# Ultra-lightweight (bash only, no Python). For constrained peers.
# Run via systemd timer: OnCalendar=*:0/10 Persistent=true
# ============================================================
set -euo pipefail

API_URL="http://127.0.0.1:8642"
LOCK_FILE="/tmp/hermes-watchdog.lock"
LOG_FILE="$HOME/.hermes/watchdog.log"
COOLDOWN_SEC=900          # 15 min between restarts
HEALTH_TIMEOUT=10         # seconds for /health curl

log() {
    echo "[$(date -Iseconds)] $*" >> "$LOG_FILE"
}

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
log "ACTION restarting hermes-gateway"
touch "$LOCK_FILE"
systemctl --user restart hermes-gateway 2>&1 | while IFS= read -r line; do
    log "restart: $line"
done

sleep 3

if curl -sf --max-time "$HEALTH_TIMEOUT" "$API_URL/health" > /dev/null 2>&1; then
    log "OK restart succeeded — health=up"
else
    log "WARN restart completed but /health still unreachable after 3s"
fi
