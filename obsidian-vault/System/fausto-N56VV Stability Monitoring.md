# fausto-N56VV Stability Monitoring

Updated: 2026-06-13T15:02:30+02:00

## Sintesi

Il PC `fausto-N56VV` ha mostrato freeze/stalli frequenti. L'analisi live del 2026-06-13 indica tre fattori principali da monitorare:

1. temperatura CPU molto alta, con picchi osservati a 95–97°C;
2. disco HDD `/dev/sda` vecchio e a rischio, con settori riallocati e pendenti;
3. carico/IO pressure elevati, specialmente quando servizi locali consumano CPU o il disco entra in forte saturazione.

L'utente ha confermato che al momento non può comprare nuovo hardware e teme giustamente test lunghi sul disco perché possono peggiorare la situazione. Politica operativa: monitorare in modo leggero, evitare stress test, evitare SMART long test finché non esiste un backup completo o finché l'utente non decide esplicitamente.

## Hardware / sistema osservato

- Host: `fausto-N56VV`
- OS: Ubuntu 22.04.5 LTS
- Kernel osservato: `5.15.0-181-generic`
- CPU: Intel Core i7-3630QM, 4 core / 8 thread, Ivy Bridge mobile, TDP 45W
- CPU Tjunction Intel: 105°C
- RAM: circa 7.6 GiB
- Swap: `/swapfile`, 2 GiB
- Disco principale: `/dev/sda`, WDC WD10JPVX-22JC3T0, HDD 1TB
- Filesystem root: ext4 su `/dev/sda2`

## Range temperatura CPU da usare

Per l'i7-3630QM:

- 35–55°C: normale idle / uso leggero;
- 55–75°C: normale sotto carico moderato;
- 75–85°C: caldo ma accettabile sotto carico;
- 85–90°C: warning, da non mantenere a lungo;
- 90–95°C: troppo caldo per uso regolare, probabile throttling;
- 95–100°C: zona instabile/pericolosa, possibili freeze, stutter o azioni di emergenza;
- 100–105°C: critico, vicino al limite Tjunction.

Policy locale:

- target sostenuto: sotto 85°C;
- warning: 80–90°C se sostenuto;
- serio: 90°C+;
- emergenza: 95°C+.

## Evidenze raccolte 2026-06-13

### Temperatura

`temp-reboot-monitor` aveva già registrato picchi:

- 14:33:28: 95.0°C, hit 1/3;
- 14:34:08: 95.0°C, hit 1/3;
- 14:34:18: 97.0°C, hit 2/3;
- 14:34:28: scesa a 89.0°C, reset contatore;
- 14:34:38: 95.0°C, hit 1/3.

Questi valori sono sufficienti a spiegare freeze o throttling su un laptop datato.

### Disco

Dopo installazione `smartmontools`, `smartd` ha segnalato subito:

- `Device: /dev/sda [SAT], 15 Currently unreadable (pending) sectors`

Attributi SMART chiave osservati:

```text
Reallocated_Sector_Ct:      1055
Reallocated_Event_Count:     102
Current_Pending_Sector:       15
Offline_Uncorrectable:         0
UDMA_CRC_Error_Count:          0
Power_On_Hours:            72849
Temperature_Celsius:          42
SMART overall-health:      PASSED
```

Interpretazione: anche se `SMART overall-health` dice `PASSED`, il disco non è affidabile. I 15 pending sectors possono causare blocchi lunghi quando il sistema legge zone problematiche. I 1055 settori riallocati indicano degrado già avanzato.

Policy: non fare test lunghi o distruttivi sul disco senza esplicita richiesta. Priorità reale: backup dati importanti e, appena possibile, sostituzione con SSD.

Comandi leggeri accettabili:

```bash
sudo smartctl -H /dev/sda
sudo smartctl -A /dev/sda | egrep 'Reallocated|Current_Pending|Offline_Uncorrectable|UDMA_CRC|Power_On_Hours|Temperature'
sudo smartctl --scan-open
```

Comandi da evitare salvo richiesta esplicita:

```bash
sudo smartctl -t long /dev/sda
badblocks ...
fsck forzati su filesystem montati
stress test I/O prolungati
```

### Carico / I/O pressure

Osservazioni live:

- load average iniziale circa `6.72, 7.09, 3.90` subito dopo boot;
- `/proc/pressure/io` inizialmente alto: `some avg60=33.35`, `full avg60=31.76`;
- `iostat` ha mostrato `/dev/sda` fino a circa 96.94% util nel campione cumulativo;
- memoria e swap non sembravano il problema primario: MemAvailable circa 4.3 GiB, swap 0 usata.

Questo supporta l'ipotesi: freeze dovuti a combinazione di temperatura alta + saturazione HDD / letture lente + servizi locali.

## Servizi e configurazioni attive

### temp-reboot-monitor

Servizio systemd di sistema:

```text
/etc/systemd/system/temp-reboot-monitor.service
/usr/local/sbin/temp-reboot-monitor
/etc/temp-reboot-monitor.conf
```

Stato atteso:

```bash
systemctl status temp-reboot-monitor.service --no-pager
journalctl -u temp-reboot-monitor.service --since '1 hour ago' --no-pager
```

Configurazione aggiornata 2026-06-14:

```bash
REBOOT_AT_C=95
CHECK_INTERVAL_SEC=10
CONSECUTIVE_HITS=30   # 30 * 10s = 5 minuti sopra soglia
COOLDOWN_C=5
MATCH_TYPES_REGEX='^(x86_pkg_temp|acpitz)$'
TELEGRAM_NOTIFY=1
TELEGRAM_ENV_FILE=/home/fausto/.hermes/.env
DRY_RUN=0
```

Comportamento:

- legge solo thermal zones CPU-like: `x86_pkg_temp` e `acpitz`;
- se la temperatura resta `>=95°C` per 30 letture consecutive, cioè circa 5 minuti, pianifica un reboot;
- il reboot non è immediato: viene pianificato con `systemd-run --on-active=2min`;
- invia messaggio Telegram, se possibile, usando token/chat Hermes da `/home/fausto/.hermes/.env`;
- crea marker `/run/temp-reboot-monitor.scheduled` per non schedulare reboot ripetuti;
- se la temperatura scende sotto cooldown (`REBOOT_AT_C - COOLDOWN_C`, quindi <=90°C), resetta il contatore e cancella il marker.

Comando configurato:

```bash
/usr/bin/systemd-run --unit=temp-safety-delayed-powercycle --on-active=2min /usr/bin/systemctl reboot --message="Temperature safety reboot: sustained CPU temperature above 95C"
```

### system-freeze-monitor

Monitor leggero ogni minuto, systemd user timer:

```text
/home/fausto/.local/bin/system-freeze-monitor
/home/fausto/.config/systemd/user/system-freeze-monitor.service
/home/fausto/.config/systemd/user/system-freeze-monitor.timer
```

Log:

```text
/home/fausto/.local/state/system-freeze-monitor/samples.log
/home/fausto/.local/state/system-freeze-monitor/alerts.log
```

Comandi:

```bash
systemctl --user status system-freeze-monitor.timer --no-pager
tail -f /home/fausto/.local/state/system-freeze-monitor/samples.log
tail -f /home/fausto/.local/state/system-freeze-monitor/alerts.log
```

Registra:

- load;
- CPU busy;
- iowait;
- temperatura massima;
- memoria disponibile;
- swap usata;
- PSI CPU/IO/memoria;
- top CPU process;
- top RAM process;
- processo `quasar-voice-detection`, se presente.

Alert locali se:

- temp >= 95°C;
- iowait >= 25%;
- IO pressure >= 20;
- load >= 8;
- MemAvailable < 512 MB.

### heavy-load-watchdog Hermes cron

Cron Hermes leggero creato 2026-06-13:

```text
job_id: cb6a13495a09
name: heavy-load-watchdog
schedule: every 5m
delivery: telegram
mode: no_agent=true
script: heavy_load_watchdog.sh
```

Script:

```text
/home/fausto/.hermes/scripts/heavy_load_watchdog.sh
```

Stato interno:

```text
/home/fausto/.local/state/system-freeze-monitor/heavy-load-watchdog.state
```

Comandi Hermes:

```bash
hermes cron list
hermes cron run cb6a13495a09
```

Oppure via tool cronjob in Hermes: list/run/update/remove.

Comportamento:

- esegue ogni 5 minuti;
- manda Telegram solo se stampa output;
- non usa LLM, non fa analisi pesanti;
- non esegue SMART long test né stress disco;
- controlla `load`, temperatura, iowait, PSI CPU/IO/memoria, memoria, swap, top process.

Soglie principali:

```text
load5 >= 6.0
io wait >= 20%
IO pressure some >= 20
CPU pressure some >= 50
memory pressure some >= 10
MemAvailable < 800 MB
temp >= 95°C
```

Critiche immediate:

```text
temp >= 95°C
iowait >= 30%
IO pressure full >= 25
```

Anti-spam:

- condizioni non critiche: alert solo dopo 2 check consecutivi, circa 10 minuti;
- cooldown 30 minuti tra messaggi non critici;
- condizioni critiche possono avvisare subito.

### smartmontools

Installato 2026-06-13:

```bash
sudo apt-get install smartmontools
```

Servizio:

```bash
systemctl status smartmontools.service --no-pager
```

Durante installazione/avvio `smartd` ha rilevato 1 device ATA/SATA e ha già segnalato i 15 pending sectors.

Nota: `smartd` tenta avvisi mail a root, ma il sistema non ha `/usr/bin/mail`. Gli alert pratici per ora passano da Hermes/Telegram tramite heavy-load-watchdog e temp-reboot-monitor.

## quasar-voice-detection

Il servizio `quasar-voice-detection` non è considerato core dall'utente. Se impatta stabilità, limitarlo/disabilitarlo è accettabile.

Percorso:

```text
/home/fausto/quasar-voice-detection
/home/fausto/quasar-voice-detection/hey_hermes.py
/home/fausto/.config/systemd/user/quasar-voice-detection.service
```

Policy aggiornata 2026-06-13:

- non deve fare join automatico della voice Discord;
- per ora deve solo ricevere il wake locale e inviare Telegram con testo `Local Voice Wakeup Detected`;
- quando l'utente deciderà cosa fare dopo il wake, aggiornare questa policy.

Implementazione corrente:

- wake file locale: `/home/fausto/.hermes/local_voice_wake_trigger.json`;
- messaggio Telegram inviato direttamente da `hey_hermes.py` usando `TELEGRAM_BOT_TOKEN` e `TELEGRAM_HOME_CHANNEL` da `/home/fausto/.hermes/.env`;
- il vecchio file osservato dal gateway per join Discord era `/home/fausto/.hermes/discord_voice_wake_trigger.json`, ma Quasar ora non lo aggiorna più.

Problema osservato:

- prima della mitigazione consumava circa 99–139% CPU;
- aveva molti thread/task;
- contribuiva a temperature alte.

Mitigazioni applicate:

1. `THRESH_FACTOR` cambiato da `1.05` a `1.40` in:

```text
/home/fausto/quasar-voice-detection/hey_hermes.py
```

2. Drop-in systemd user:

```text
/home/fausto/.config/systemd/user/quasar-voice-detection.service.d/resource-limits.conf
```

Contenuto:

```ini
[Service]
Environment=OMP_NUM_THREADS=1
Environment=OPENBLAS_NUM_THREADS=1
Environment=MKL_NUM_THREADS=1
Environment=NUMEXPR_NUM_THREADS=1
Nice=10
CPUQuota=60%
```

Dopo mitigazione, CPU e temperatura sono scese sensibilmente nel campione immediato.

Comandi utili:

```bash
systemctl --user status quasar-voice-detection.service --no-pager
systemctl --user restart quasar-voice-detection.service
journalctl --user -u quasar-voice-detection.service --since '30 minutes ago' --no-pager
```

Se il sistema torna instabile, prima azione sicura:

```bash
systemctl --user stop quasar-voice-detection.service
```

Se serve disabilitarlo:

```bash
systemctl --user disable --now quasar-voice-detection.service
```

## Cosa fare se il sistema freeza ancora

1. Dopo riavvio, controllare gli ultimi eventi:

```bash
journalctl -u temp-reboot-monitor.service --since '2 hours ago' --no-pager
journalctl --user -u system-freeze-monitor.service --since '2 hours ago' --no-pager
tail -100 /home/fausto/.local/state/system-freeze-monitor/alerts.log
tail -100 /home/fausto/.local/state/system-freeze-monitor/samples.log
```

2. Controllare se il watchdog Hermes ha mandato alert Telegram.

3. Controllare rapidamente disco senza stress:

```bash
sudo smartctl -A /dev/sda | egrep 'Reallocated|Current_Pending|Offline_Uncorrectable|UDMA_CRC|Power_On_Hours|Temperature'
```

4. Se temperatura alta:

- fermare processi non core;
- considerare stop di `quasar-voice-detection`;
- evitare compilazioni/build pesanti;
- lasciare raffreddare macchina;
- pulizia ventole / pasta termica quando possibile.

5. Se iowait/IO pressure alto:

- evitare aggiornamenti grossi, indicizzazioni, sync massivi;
- fermare servizi che fanno scansione/indicizzazione se necessario;
- non lanciare test disco pesanti;
- pianificare backup leggero e incrementale.

## Policy operativa per Hermes

- Rispondere in italiano di default.
- Non lanciare `smartctl -t long`, `badblocks`, stress test o operazioni di lettura massiva senza consenso esplicito.
- Preferire monitoraggio leggero via `/proc`, `smartctl -A`, `journalctl`, systemd status, PSI.
- Se il sistema mostra temperatura sostenuta o IO pressure, privilegiare riduzione carico e notifiche rispetto a diagnosi invasive.
- Ricordare che nuovo hardware non è disponibile subito: lavorare con mitigazioni software e backup prudente.
