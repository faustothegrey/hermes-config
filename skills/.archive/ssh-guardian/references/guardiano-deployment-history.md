# Guardiano SSH — Italian Deployment History

Originally authored as a separate skill (`guardiano-ssh`) describing the same
system in Italian, before being consolidated into `ssh-guardian`. This file
preserves the original Italian viewpoint and specific deployment details.

## Original architecture diagram (Italian)

```
Utente → "apri 2222" → Hermes (chat/Telegram)
  → guardiano.sh open → iptables ACCEPT inserito
  → cron watchdog ogni 2 min → timer

18 min → watchdog rileva warning → Telegram: "scade tra 2'"
Utente → "sì" → tocca flag → watchdog resetta timer a +20 min

20 min → watchdog senza flag → iptables ACCEPT rimosso → Telegram: "chiusa"
```

## Component file paths

| Component | Path |
|-----------|------|
| State file | `/tmp/guardiano-state.json` |
| Keepalive flag | `/tmp/guardiano-keepalive` |
| Log file | `/tmp/guardiano.log` |
| Cron entry (absolute) | `*/2 * * * * /home/fausto/.hermes/scripts/guardiano-watchdog.sh` |

## Original security notes (Italian)

- **Porta 22**: sempre aperta in LAN, inalterata
- **Porta 2222**: esposta via internet (port forwarding router), ma bloccata da
  iptables di default
- **Regola iptables** di default: `DROP tcp --dport 2222`
- **Regola temporanea**: `ACCEPT tcp --dport 2222` (inserita prima della DROP)
- **Autenticazione**: il canale Telegram Hermes (solo l'utente autorizzato)
- **Timeout automatico**: se l'utente si dimentica, si chiude da sola

## Specific deployment

- Router port forward: external port → **192.168.178.84:2222**
- Hostname: `N56VV` (Asus laptop, old hardware)
- Users interact in Italian: "apri 2222", "chiudi 2222", "sì"
