#!/usr/bin/env bash
# Faro Beacon — segnale "sono tornato" all'orchestratore
# Uso: beacon.sh <peer_name> [once|check]
set -euo pipefail
ORCHESTRATOR="192.168.178.84"
PORT="9191"
PEER="${1:-}"
MODE="${2:-once}"
[ -z "$PEER" ] && { echo "Usage: $0 <peer_name>" >&2; exit 1; }
URL="http://${ORCHESTRATOR}:${PORT}/beacon/${PEER}"
LOCK="/tmp/faro-${PEER}.lock"

if [ "$MODE" = "check" ] && [ -f "$LOCK" ]; then
    exit 0  # già online, niente da fare
fi

HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    touch "$LOCK"
else
    rm -f "$LOCK"
    exit 1
fi