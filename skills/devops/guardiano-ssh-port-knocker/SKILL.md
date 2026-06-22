---
name: guardiano-ssh-port-knocker
description: "Guardiano SSH — porta SSH secondaria controllata via Telegram con timer e keepalive. Apre/chude iptables su comando dell'utente via chat Hermes."
version: 1.0.0
tags: [ssh, security, telegram, iptables, port-knocking]
---

# Guardiano SSH — Port Knocker via Telegram

## Architettura
- SSH ascolta su porte 22 (LAN) e 2222 (WAN via port forwarding)
- **2222 bloccata da iptables** (DROP) di default
- Apertura su comando dell'utente: "apri 2222" → iptables ACCEPT
- Timer 20 min — a 18 min cron manda avviso Telegram
- Utente risponde "sì" → timer resetta
- Scaduto → iptables DROP, Telegram notifica
- "chiudi 2222" → chiusura immediata

## Componenti
- `~/.hermes/scripts/guardiano.sh` — gestisce stato, iptables, timer
- `~/.hermes/scripts/guardiano-watchdog.sh` — cron */2, invia avvisi Telegram via `hermes send`
- Cron: `*/2 * * * * /home/fausto/.hermes/scripts/guardiano-watchdog.sh`
- Timer: `/tmp/guardiano-state.json` con expires_at
- Keepalive: `/tmp/guardiano-keepalive` (flag)

## Comandi utente
- "apri 2222" → iptables ACCEPT + timer 20 min
- "sì" (in finestra avviso) → timer +20 min
- "chiudi 2222" → chiusura immediata
- "la porta?" / "com'è la porta" → mostra stato

## Porte gestite (stessa vita, stesso timer)
- 2222 — SSH WAN
- 3001 — Web app
- Router: esterno:XXX → N56VV:2222 e YYY → N56VV:3001
- Porta 22 lasciata solo LAN

## Comandi utente
- "apriti sedano" → apre 2222 + 3001 per 20 min
- "Sisisi" (in finestra avviso Telegram) → timer +20 min
- "chiudi 2222" → chiude entrambe
- "la porta?" / "com'è la porta" → mostra stato

## Note
- `hermes send -t telegram` per inviare messaggi senza LLM
- iptables: ACCEPT inserito prima della regola DROP
- sudo senza password configurato