#!/usr/bin/env bash
# Guardiano Watchdog — cron */2
set -euo pipefail
OUTPUT=$(/home/fausto/.hermes/scripts/guardiano.sh watchdog 2>&1 || true)
[ -z "$OUTPUT" ] && exit 0
echo "$OUTPUT"
if echo "$OUTPUT" | grep -q "^AVVISO:"; then
    MESSAGE="⏳ ${OUTPUT#AVVISO:}"
    MESSAGE+=$'\n\n_Rispondi "sì" per tenere aperta la porta._'
    echo "$MESSAGE" | hermes send -t telegram --quiet 2>/dev/null || true
elif echo "$OUTPUT" | grep -q "Porta chiusa per timeout"; then
    echo "🔒 SSH:2222 chiusa per timeout di inattività." | hermes send -t telegram --quiet 2>/dev/null || true
elif echo "$OUTPUT" | grep -q "^✅ Keepalive"; then
    echo "✅ ${OUTPUT#✅ }" | hermes send -t telegram --quiet 2>/dev/null || true
fi