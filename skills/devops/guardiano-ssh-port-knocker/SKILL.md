---
name: guardiano-ssh-port-knocker
description: "Guardiano SSH — porta SSH secondaria controllata via Telegram con timer e keepalive. Apre/chude iptables su comando dell'utente via chat Hermes. Gestisce anche il port forwarding UPnP sul FritzBox di casa."
version: 1.1.0
tags: [ssh, security, telegram, iptables, port-knocking, upnp, fritzbox]
---

# Guardiano SSH — Port Knocker via Telegram

## Two-Layer Architecture

L'accesso esterno ha DUE livelli distinti, NON confondere:

1. **FritzBox UPnP** — port forwarding dal router all'host LAN. Cosa arriva dall'esterno.
2. **iptables locali** (Guardiano) — blocco/sblocco sulla macchina stessa. Cosa passa dopo che è arrivato.

Guardiano gestisce SOLO il livello 2 (iptables). Il livello 1 (UPnP FritzBox) si gestisce con `upnpc` (miniupnpc).

## Scenario tipico: reach esterna via N56VV

```
Esterno --> FritzBox WAN:2222 --[UPnP forward]--> peer84(LAN):2222 --[iptables]--> peer84:22 (SSH)
```

- FritzBox traduce 2222 WAN -> 2222 LAN su peer84 (N56VV)
- Guardiano blocca/sblocca 2222 su peer84 via iptables
- SSH su peer84 ascolta su 2222 (e 22 LAN)

## Scenario alternativo: jump host via peer70 (RPi, sempre-on)

Quando peer84 (N56VV) è in cooling period, il ponte esterno passa da peer70:

```
Esterno --> FritzBox WAN:2222 --[UPnP forward]--> peer70(LAN):22 --[SSH jump]--> peer128(LAN):22
```

Peer70 (RPi, 192.168.178.70) è sempre acceso, senza finestre termiche. Ideale come jump host 24/7 verso il Mac peer128.

## UPnP FritzBox — comandi essenziali

Tutti via `upnpc` (miniupnpc, già installato su N56VV). FritzBox IGD su 192.168.178.1:49000.

```bash
# Lista tutte le port forwarding rules esistenti
upnpc -l

# Aggiungere una regola: -a <IP> <porta_interna> <porta_esterna> <protocollo>
upnpc -a 192.168.178.70 22 2222 TCP

# Rimuovere una regola: -d <porta_esterna> <protocollo>
upnpc -d 2222 TCP

# Verificare IP esterno
upnpc -l | grep ExternalIPAddress
```

Le regole UPnP NON hanno timer di scadenza (lease=0, permanenti finché non rimosse). A differenza di iptables, non si autochiudono.

## Architettura Guardiano (iptables locali)

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
- `~/.hermes/skills/devops/guardiano-ssh-port-knocker/references/fritzbox-upnp.md` — dettagli UPnP FritzBox
- Cron: `*/2 * * * * /home/fausto/.hermes/scripts/guardiano-watchdog.sh`
- Timer: `/tmp/guardiano-state.json` con expires_at
- Keepalive: `/tmp/guardiano-keepalive` (flag)

## Comandi utente
- "apri 2222" → iptables ACCEPT + timer 20 min
- "sì" (in finestra avviso) → timer +20 min
- "chiudi 2222" → chiusura immediata
- "la porta?" / "com'è la porta" → mostra stato
- "apriti sedano" → apre 2222 + 3001 per 20 min
- "Sisisi" (in finestra avviso Telegram) → timer +20 min

## Porte gestite (stessa vita, stesso timer)
- 2222 — SSH WAN
- 3001 — Web app
- Porta 22 lasciata solo LAN

## Note
- `hermes send -t telegram` per inviare messaggi senza LLM
- iptables: ACCEPT inserito prima della regola DROP
- sudo senza password configurato
- Vedi `references/fritzbox-upnp.md` per dettagli su query UPnP, stato attuale, troubleshooting