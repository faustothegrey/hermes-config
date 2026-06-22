#!/usr/bin/env bash
# Faro Monitor — cron */5
set -euo pipefail
LISTENER_PORT=9191
if ! curl -sf -o /dev/null --connect-timeout 2 "http://localhost:${LISTENER_PORT}/health" 2>/dev/null; then
    python3 "${HOME}/.hermes/scripts/beacon-listener.py" --port "$LISTENER_PORT" &
    sleep 1
fi
STATUS_DIR="${HOME}/.hermes/peer-status"
STATUS_FILE="${STATUS_DIR}/status.json"
TRANSITIONS="${STATUS_DIR}/transitions.jsonl"
BEACON_LOG="${STATUS_DIR}/beacon.log"
PREV_FILE="${STATUS_DIR}/.previous-state.json"
mkdir -p "$STATUS_DIR"
PEERS=(peer105 peer106 peer128)
URLS=(  http://192.168.178.105:8642/health  http://192.168.178.106:8642/health  http://192.168.178.128:8642/health  )
declare -A CURRENT
for i in "${!PEERS[@]}"; do
    p="${PEERS[$i]}"
    code=$(curl -sf -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "${URLS[$i]}" 2>/dev/null || echo "000")
    CURRENT["$p"]=$([ "$code" = "200" ] && echo "online" || echo "offline")
done
LAST_BEACON=""; [ -f "$BEACON_LOG" ] && LAST_BEACON=$(tail -1 "$BEACON_LOG" 2>/dev/null)
python3 -c "
import json, os
now = '$NOW_ISO'; now_ts = $NOW_TS; bf = '$BEACON_LOG'
peers_raw = {$(for p in "${!PEERS[@]}"; do echo "'$p': '${CURRENT[$p]}',"; done)}
pf = '$PREV_FILE'
prev = json.load(open(pf)) if os.path.exists(pf) else {}
peers_out = {}
for pn, st in peers_raw.items():
    entry = {'status': st, 'last_checked': now}
    if st == 'online':
        entry['last_seen_online'] = now
    elif pn in prev.get('peers', {}):
        entry['last_seen_online'] = prev['peers'][pn].get('last_seen_online', 'never')
    else:
        entry['last_seen_online'] = 'never'
    entry['consecutive_failures'] = prev.get('peers', {}).get(pn, {}).get('consecutive_failures', 0) + 1 if st == 'offline' else 0
    peers_out[pn] = entry
lb = ''; 
if os.path.exists(bf):
    try: lb = open(bf).readlines()[-1].strip()
    except: pass
o = {'timestamp': now, 'ts': now_ts, 'peers': peers_out, 'last_beacon': lb, 'summary': {'total': len(peers_raw), 'online': sum(1 for s in peers_raw.values() if s=='online'), 'offline': sum(1 for s in peers_raw.values() if s=='offline')}}
json.dump(o, open('$STATUS_FILE','w'), indent=2)
json.dump(o, open('$PREV_FILE','w'), indent=2)
print(f\"{o['summary']['online']}/{o['summary']['total']} online\")
for p, s in peers_raw.items(): print(f'  {p}: {s}')
" 2>/dev/null