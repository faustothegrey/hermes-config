#!/usr/bin/env bash
# Guardiano SSH — Telegram-controllato, temporizzato
set -euo pipefail

PORT=2222
STATE_FILE="/tmp/guardiano-state.json"
KEEPALIVE_FLAG="/tmp/guardiano-keepalive"
OPEN_MINUTES=20
WARN_MINUTES=2
NOW=$(date +%s)

open_port() {
    sudo iptables -C INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null && return 0
    sudo iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') PORTA APERTA" >> /tmp/guardiano.log
    EXPIRES=$((NOW + OPEN_MINUTES * 60))
    cat > "$STATE_FILE" <<EOF
{"port":$PORT,"status":"open","opened_at":$NOW,"expires_at":$EXPIRES,"warned":false}
EOF
    echo "✅ SSH:$PORT aperta fino a $(date -d @$EXPIRES '+%H:%M')"
}

close_port() {
    sudo iptables -D INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || true
    rm -f "$STATE_FILE" "$KEEPALIVE_FLAG"
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') PORTA CHIUSA" >> /tmp/guardiano.log
    echo "🔒 SSH:$PORT chiusa"
}

check_status() {
    if [ ! -f "$STATE_FILE" ]; then echo "CHIUSA"; return 0; fi
    local expires; expires=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['expires_at'])" 2>/dev/null || echo "0")
    local remaining=$((expires - NOW))
    if [ $remaining -le 0 ]; then echo "SCADUTA (chiudere)"; else echo "APERTA (${remaining}s rimanenti)"; fi
}

apply_keepalive() {
    if [ ! -f "$STATE_FILE" ]; then echo "Nessuna sessione attiva"; exit 1; fi
    touch "$KEEPALIVE_FLAG"; echo "✅ Keepalive registrato"
}

watchdog() {
    if [ ! -f "$STATE_FILE" ]; then exit 0; fi
    local expires warned
    expires=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['expires_at'])" 2>/dev/null || echo "0")
    warned=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['warned'])" 2>/dev/null || echo "false")
    local remaining=$((expires - NOW))

    if [ -f "$KEEPALIVE_FLAG" ]; then
        rm -f "$KEEPALIVE_FLAG"
        local new_expires=$((NOW + OPEN_MINUTES * 60))
        python3 -c "import json; s=json.load(open('$STATE_FILE')); s['expires_at']=$new_expires; s['warned']=False; json.dump(s, open('$STATE_FILE','w'))"
        echo "✅ Keepalive: timer resettato +20 min (scade $(date -d @$new_expires '+%H:%M'))"
        exit 0
    fi

    if [ $remaining -le 0 ]; then close_port; echo "⏰ Porta chiusa per timeout"; exit 0; fi

    if [ $remaining -le $((WARN_MINUTES * 60)) ] && [ "$warned" = "false" ]; then
        python3 -c "import json; s=json.load(open('$STATE_FILE')); s['warned']=True; json.dump(s, open('$STATE_FILE','w'))"
        echo "AVVISO:SSH:$PORT scade tra ${remaining}s. Rispondi 'sì' per tenere aperta."
    fi
}

case "${1:-status}" in
    open) open_port ;; close) close_port ;; status) check_status ;;
    keepalive) apply_keepalive ;; watchdog) watchdog ;;
    *) echo "Usage: $0 {open|close|status|keepalive|watchdog}" >&2; exit 1 ;;
esac