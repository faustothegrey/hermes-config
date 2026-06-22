---
name: guardiano-ssh
description: "Guardiano SSH — apre/chude porta 2222 via iptables su comando Telegram, con timer 20min e keepalive."
version: 1.0.0
author: Hermes Agent
tags: [ssh, security, telegram, iptables, port-knocking]
---

# Guardiano SSH

Sistema di apertura temporanea della porta SSH 2222 via Telegram.

## Architettura

```
Utente → "apri 2222" → Hermes (chat/Telegram)
  → guardiano.sh open → iptables ACCEPT inserito
  → cron watchdog ogni 2 min → timer

18 min → watchdog rileva warning → Telegram: "scade tra 2'"
Utente → "sì" → tocca flag → watchdog resetta timer a +20 min

20 min → watchdog senza flag → iptables ACCEPT rimosso → Telegram: "chiusa"
```

## Comandi

Per attivare: l'utente dice "apri 2222" in qualsiasi canale (chat o Telegram).
Io (l'agente) eseguo:
```bash
bash ~/.hermes/scripts/guardiano.sh open
```

Per chiudere prima del timeout: l'utente dice "chiudi 2222".
Io eseguo:
```bash
bash ~/.hermes/scripts/guardiano.sh close
```

Per sapere lo stato:
```bash
bash ~/.hermes/scripts/guardiano.sh status
```

## Componenti

- `~/.hermes/scripts/guardiano.sh` — gestore stato (open/close/status/keepalive/watchdog)
- `~/.hermes/scripts/guardiano-watchdog.sh` — cron wrapper che chiama `guardiano.sh watchdog` e inoltra eventi su Telegram via `hermes send`
- Cron: `*/2 * * * * /home/fausto/.hermes/scripts/guardiano-watchdog.sh`
- State file: `/tmp/guardiano-state.json`
- Keepalive flag: `/tmp/guardiano-keepalive`
- Log: `/tmp/guardiano.log`

## Keepalive

Quando il watchdog (cron */2) rileva che mancano 2 min alla scadenza:
1. Imposta `warned: true` nello state file
2. Il watchdog script invia su Telegram: "⏳ SSH:2222 scade tra 2 min, rispondi sì"

Se l'utente risponde "sì":
1. Io tocco il file `/tmp/guardiano-keepalive`
2. Al prossimo giro del watchdog (max 2 min), resetta il timer a +20 min
3. Invia conferma Telegram: "✅ Riaperta per altri 20 min"

Se nessun "sì" arriva entro 2 min:
1. Watchdog chiude la porta (rimuove regola ACCEPT da iptables)
2. Invia Telegram: "🔒 SSH:2222 chiusa per timeout"

## Sicurezza

- Porta 22: sempre aperta in LAN, inalterata
- Porta 2222: esposta via internet (port forwarding router), ma bloccata da iptables di default
- Regola iptables di default: `DROP tcp --dport 2222`
- Regola temporanea: `ACCEPT tcp --dport 2222` (inserita prima della DROP)
- Autenticazione: il canale Telegram Hermes (solo l'utente autorizzato)
- Timeout automatico: se l'utente si dimentica, si chiude da sola

## Port forwarding router

Il router deve fare forward da porta esterna (es. 2222 o altra) a 192.168.178.84:2222.