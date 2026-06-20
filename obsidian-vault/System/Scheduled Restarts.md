# Scheduled Restarts

Status updated 2026-06-14: the fixed daily scheduled restarts are disabled.

Previous daily restart times were:

- 00:00
- 06:00
- 12:00
- 18:00

Current policy:

- Do not rely on preventive scheduled restarts while the system remains stable.
- Keep background health monitoring active.
- If a genuinely dangerous thermal condition is detected, send alerts via Telegram and email, then perform a complete poweroff.
- If unexpected freezes return, bring back scheduled restarts.

Operational implications:

- Long tasks no longer need to avoid the old daily restart windows by default.
- Still checkpoint important long-running work because emergency poweroff can happen if the thermal safety threshold is sustained.

Verification 2026-06-14 19:42 CEST:

- Root crontab checked: no fixed restart entries remain.
- `temp-reboot-monitor.service` checked active as `Temperature safety poweroff monitor`.
- Telegram + Virgilio email alert test was confirmed successful by the user.
- Detailed live-state snapshot and exact safety configuration are in [[System/fausto-N56VV Stability Monitoring]].

---

## Breakthrough — Scheduled Reboot 2026-06-20

**Stato**: `rtcwake -m off` schedulato funziona perfettamente.

### Nightly Cooling Period (attivo dal 2026-06-20)

| Campo | Valore |
|-------|--------|
| Job Hermes | `N56VV Nightly Cooling Period` |
| Job ID | `4290847cf173` |
| Schedule | `0 1 * * *` (1:00 AM ogni notte) |
| Script | `~/.hermes/scripts/cooling-period.sh` |
| Comando | `sudo rtcwake -m off -s 18000` (5 ore) |
| Spegnimento | 1:00 AM |
| Riaccensione | 6:00 AM (via RTC) |
| Modalità | `no_agent=true` |

### Job modificati per evitare la finestra

- **Peer105+106 Loop**: schedule spostato da `0 6,10,14,18,22` a `0 7,10,14,18,22` (6:00 → 7:00, margine post-riaccensione)
- **Peer105 Heartbeat** e **Peer106 Heartbeat**: lasciati invariati — non girano quando N56VV è spento
- **heavy-load-watchdog**: lasciato invariato — non gira quando N56VV è spento

### Dettagli implementazione

```bash
# ~/.hermes/scripts/cooling-period.sh
#!/bin/bash
# Pre: cattura statistiche termiche prima dello spegnimento
/home/fausto/.hermes/scripts/cooling-stats.sh --pre
# Shutdown con wake programmato (5 ore)
sudo rtcwake -m off -s 18000
```

Lo script spegne N56VV via `rtcwake -m off` con wake programmato dopo 18000 secondi (5 ore). Prima dello shutdown cattura le statistiche termiche (`cooling-stats.sh --pre`). La scheda RTC della motherboard mantiene il tempo e riaccende l'alimentazione alle 6:00. Hermes (systemd) riparte automaticamente al boot successivo, e i cronjob riprendono.

### Stats Monitoring aggiunto (2026-06-20)

Alle 06:10 un nuovo job `N56VV Cooling Stats Report` (`3d9f08a47adf`) cattura le stats post-riavvio e genera un report comparativo. Dettagli su [[System/fausto-N56VV Stability Monitoring#Stats Monitoring System — 2026-06-20]].
