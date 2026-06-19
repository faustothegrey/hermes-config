#!/bin/bash
# Constrained-peer watchdog — checks Hermes API /health, restarts gateway on
# failure with a cooldown lock file. Designed for low-RAM ARM SBCs with
# unstable free-tier models.
#
# Deploy: ~/.hermes/scripts/watchdog.sh, chmod +x
# Systemd timer: OnCalendar=*:0/10, Persistent=true (oneshot service)
#
# The lock file uses mtime (not system clock) because constrained SBCs often
# have broken RTCs that reset on reboot.
set -euo pipefail

API_URL="http://127.0.0.1:8642"
LOCK_FILE="/tmp/hermes-watchdog.lock"
LOG_FILE="$HOME/.hermes/watchdog.log"
COOLDOWN_SEC=900
HEALTH_TIMEOUT=10

log() { echo "[$(date -Iseconds)] $*" >> "$LOG_FILE"; }

# Check health
if curl -sf --max-time "$HEALTH_TIMEOUT" "$API_URL/health" > /dev/null 2>&1; then
    log "OK health=up"
    exit 0
fi

log "ERROR health=down"

# Cooldown check using lock file mtime, not system clock
now=$(date +%s)
last_restart=0
[ -f "$LOCK_FILE" ] && last_restart=$(stat -c %Y "$LOCK_FILE" 2>/dev/null) || true

if [ $((now - last_restart)) -lt $COOLDOWN_SEC ]; then
    remaining=$(( (COOLDOWN_SEC - (now - last_restart)) / 60 ))
    log "SKIP restart cooldown ${remaining}m"
    exit 0
fi

# Restart gateway
log "ACTION restarting hermes-gateway"
touch "$LOCK_FILE"
systemctl --user restart hermes-gateway 2>&1 | while read -r line; do log "restart: $line"; done
sleep 3

# Verify recovery
if curl -sf --max-time "$HEALTH_TIMEOUT" "$API_URL/health" > /dev/null 2>&1; then
    log "OK restart succeeded"
else
    log "WARN restart done but health still down"
fi
