#!/usr/bin/env bash
# verify-service.sh — one-shot systemd service verification
# Usage: ./verify-service.sh <service-name> [health-url]
set -euo pipefail

SERVICE="${1:?Usage: $0 <service-name> [health-url]}"
HEALTH_URL="${2:-}"

echo "=== Service: $SERVICE ==="

# 1. systemd status
echo "--- systemctl status ---"
if systemctl is-active --quiet "$SERVICE"; then
    echo "Status: ACTIVE ✓"
else
    echo "Status: $(systemctl is-active "$SERVICE" 2>/dev/null || echo 'INACTIVE') ✗"
fi

if systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
    echo "Enabled: YES ✓"
else
    echo "Enabled: NO ✗"
fi

# 2. Logs (last 5 lines)
echo "--- recent log ---"
UNIT=$(systemctl show -p Id "$SERVICE" 2>/dev/null | cut -d= -f2)
if [ -n "$UNIT" ]; then
    journalctl -u "$UNIT" -n 5 --no-pager 2>/dev/null || echo "(no journal entries)"
fi

# 3. HTTP health check
if [ -n "$HEALTH_URL" ]; then
    echo "--- HTTP health ---"
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$HEALTH_URL" 2>/dev/null || echo "TIMEOUT/ERR")
    echo "$HEALTH_URL → HTTP $HTTP_CODE"
    if [ "$HTTP_CODE" = "200" ]; then
        echo "HTTP: OK ✓"
    else
        echo "HTTP: FAIL ✗"
    fi
fi

echo "=== done ==="