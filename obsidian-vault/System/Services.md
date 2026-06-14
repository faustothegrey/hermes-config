# Services

## domotz.service

Disabilitato permanentemente il 2026-06-14 perché falliva all'avvio con timeout e lasciava processi residui.

Stato verificato dopo intervento:

```text
systemctl is-enabled domotz.service -> masked
systemctl is-active domotz.service  -> inactive
Loaded: masked (Reason: Unit domotz.service is masked.)
Active: inactive (dead)
```

Comandi usati:

```bash
sudo systemctl disable --now domotz.service
sudo systemctl mask domotz.service
sudo systemctl reset-failed domotz.service
```

Per riabilitarlo esplicitamente in futuro:

```bash
sudo systemctl unmask domotz.service
sudo systemctl enable --now domotz.service
```

## butler.service

Servizio systemd di sistema per ScienceClick2 / Domotz Butler.

Comandi utili:

```bash
sudo systemctl restart butler.service
systemctl status butler.service --no-pager --lines=30
```

Dettagli osservati:

- unit file: `/etc/systemd/system/butler.service`;
- working command: `/bin/bash /home/fausto/Software/ScienceClick2/service_start.sh`;
- app Next.js su `http://localhost:3001`;
- URL rete osservato: `http://192.168.178.84:3001`.

Nota: npm può stampare warning su Node.js v24.15.0, ma il servizio può comunque partire correttamente.

## Stabilità fausto-N56VV

Vedi nota dettagliata: [[fausto-N56VV Stability Monitoring]].

Servizi/watchdog principali:

- `temp-reboot-monitor.service`: monitor termico root; reboot pianificato se temperatura CPU-like resta >=95°C per 5 minuti;
- `smartmontools.service`: SMART daemon, ha segnalato 15 pending sectors su `/dev/sda`;
- `system-freeze-monitor.timer`: campionamento leggero ogni minuto in user systemd;
- Hermes cron `heavy-load-watchdog` (`cb6a13495a09`): alert Telegram ogni 5 minuti se carico/temperatura/IO pressure restano alti.

Policy: evitare test disco lunghi o stressanti senza consenso esplicito perché `/dev/sda` è degradato.
