#!/usr/bin/env bash
# Faro Beacon — per peer portatile (macOS), rileva cambio rete
# Uso: installare come cron */2 * * * *
ORCHESTRATOR="192.168.178.84"
PORT="9191"
PEER="peer128"
LOCK="/tmp/faro-${PEER}.lock"
LOG="${HOME}/.hermes/peer-status/beacon-client.log"
mkdir -p "$(dirname "$LOG")"
log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*" >> "$LOG"; }

HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://${ORCHESTRATOR}:${PORT}/health" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    if [ ! -f "$LOCK" ]; then
        log "Rete di casa rilevata, invio beacon..."
        BC=$(curl -sf -o /dev/null -w "%{http_code}" "http://${ORCHESTRATOR}:${PORT}/beacon/${PEER}" 2>/dev/null || echo "000")
        [ "$BC" = "200" ] && { log "Beacon OK"; touch "$LOCK"; } || log "Beacon fallito $BC"
    fi
else
    [ -f "$LOCK" ] && { log "Connessione LAN persa"; rm -f "$LOCK"; }
fi