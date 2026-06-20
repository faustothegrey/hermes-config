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

Configurazione aggiornata 2026-06-14 sera:

```bash
REBOOT_AT_C=95
CHECK_INTERVAL_SEC=10
CONSECUTIVE_HITS=30   # 30 * 10s = 5 minuti sopra soglia
COOLDOWN_C=5
MATCH_TYPES_REGEX='^(x86_pkg_temp|acpitz)$'
TELEGRAM_NOTIFY=1
TELEGRAM_ENV_FILE=/home/fausto/.hermes/.env
EMAIL_NOTIFY=1
EMAIL_TO=fausto.lelli@gmail.com
EMAIL_FROM=fausto.lelli@virgilio.it
EMAIL_SMTP_HOST=smtp.virgilio.it
EMAIL_SMTP_PORT=465
EMAIL_SMTP_LOGIN=fausto.lelli@virgilio.it
EMAIL_PASSWORD_CMD=/home/fausto/.config/himalaya/virgilio-password
DRY_RUN=0
```

Comportamento:

- legge solo thermal zones CPU-like: `x86_pkg_temp` e `acpitz`;
- se la temperatura resta `>=95°C` per 30 letture consecutive, cioè circa 5 minuti, pianifica uno spegnimento completo;
- lo spegnimento non è immediato: viene pianificato con `systemd-run --on-active=2min` per dare tempo agli alert;
- invia messaggio Telegram, se possibile, usando token/chat Hermes da `/home/fausto/.hermes/.env`;
- invia anche email da Virgilio a `fausto.lelli@gmail.com` usando SMTP e il password command Himalaya;
- crea marker `/run/temp-reboot-monitor.scheduled` per non schedulare azioni ripetute;
- se la temperatura scende sotto cooldown (`REBOOT_AT_C - COOLDOWN_C`, quindi <=90°C), resetta il contatore e cancella il marker.

Comando configurato:

```bash
/usr/bin/systemd-run --unit=temp-safety-delayed-powercycle --on-active=2min /usr/bin/systemctl poweroff --message="Temperature safety poweroff: sustained CPU temperature above 95C"
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

## Verifica policy senza riavvii fissi — 2026-06-14 19:42 CEST

Richiesta utente: ricontrollare stato, compattare memoria Hermes, e tenere i dettagli nel vault.

### Stato live verificato

- Uptime: circa 1h41m.
- Load average: `0.02 0.07 0.10`.
- Memoria: 7.6 GiB totali, circa 5.0 GiB disponibili.
- Swap: 2.0 GiB totali, 0 usata.
- Disco root `/`: 916G totali, 352G usati, 518G liberi, 41% uso.
- PSI CPU/memoria: 0.00; PSI IO presente ma basso (`avg60` circa 0.38).
- Temperature thermal zone: `acpitz` circa 74°C, `x86_pkg_temp` circa 76°C.
- Failed units di sistema e user: 0.

### Riavvii programmati

Root crontab ricontrollato: non contiene più le vecchie righe di riavvio giornaliero a 00/06/12/18.

### Monitor termico safety

Servizio:

```text
temp-reboot-monitor.service - Temperature safety poweroff monitor
```

Stato verificato:

```text
active (running)
```

Configurazione confermata:

```bash
REBOOT_AT_C=95
CHECK_INTERVAL_SEC=10
CONSECUTIVE_HITS=30
SAFETY_ACTION_COMMAND='/usr/bin/systemd-run --unit=temp-safety-delayed-powercycle --on-active=2min /usr/bin/systemctl poweroff --message="Temperature safety poweroff: sustained CPU temperature above 95C"'
TELEGRAM_NOTIFY=1
EMAIL_NOTIFY=1
EMAIL_TO=fausto.lelli@gmail.com
EMAIL_FROM=fausto.lelli@virgilio.it
EMAIL_SMTP_HOST=smtp.virgilio.it
EMAIL_SMTP_PORT=465
EMAIL_SMTP_LOGIN=fausto.lelli@virgilio.it
EMAIL_PASSWORD_CMD=/home/fausto/.config/himalaya/virgilio-password
DRY_RUN=0
```

Nota: il test alert manuale Telegram + email è stato confermato riuscito dall'utente. Il test non ha creato marker `/run/temp-reboot-monitor.scheduled` e non ha pianificato spegnimento.

### Monitor leggeri ancora attivi

- Hermes cron `heavy-load-watchdog`: ogni 5 minuti, `no_agent=true`, delivery Telegram, ultimo stato `ok`.
- `system-freeze-monitor.timer`: attivo, campionamento circa ogni minuto.
- `hermes-gateway.service`: necessario per delivery/cron Hermes, precedentemente verificato attivo.

### Memoria Hermes compattata

La user memory è stata ridotta rimuovendo dettagli duplicati sulla voce/TTS e sostituendo la policy riavvii con una frase compatta che punta a queste note:

- `[[System/Scheduled Restarts]]`
- `[[System/fausto-N56VV Stability Monitoring]]`

Principio futuro: mantenere nel prompt solo policy brevi e link Obsidian; lasciare soglie, comandi, output e test nel vault.

---

## Nightly Cooling Period — 2026-06-20

**Breakthrough**: `rtcwake -m off` schedulato via Hermes cron ora funziona stabilmente. Strategia adottata per gestire il surriscaldamento senza intervento fisico immediato.

### Cos'è

N56VV va in **spegnimento programmato ogni notte da 1:00 a 6:00** per dare alla CPU 5 ore di raffreddamento completo. Questo previene accumuli termici e riduce il rischio di freeze notturni.

### Implementazione

```bash
# ~/.hermes/scripts/cooling-period.sh
#!/bin/bash
sudo rtcwake -m off -s 18000
```

- `rtcwake -m off` spegne il sistema ma RTC rimane attivo
- `-s 18000` = riaccensione dopo 18000 secondi (5 ore esatte)
- Hermes cron esegue lo script all'1:00, poi la macchina si spegne
- Alle 6:00 RTC riaccende, il sistema fa boot, Hermes (systemd) riparte

### Cronjob Hermes

| Campo | Valore |
|-------|--------|
| Nome | `N56VV Nightly Cooling Period` |
| Job ID | `4290847cf173` |
| Schedule | `0 1 * * *` |
| Script | `cooling-period.sh` |
| Modalità | `no_agent=true` (nessun LLM, solo script shell) |
| Delivery | `local` |

### Job adattati

Il **Peer105+106 Autonomous Loop** è stato spostato da `0 6,10,14,18,22` a `0 7,10,14,18,22` per dare 1h di margine dopo la riaccensione delle 6:00.

I job heartbeat (Peer105, Peer106) e il watchdog (heavy-load-watchdog) non sono stati modificati — semplicemente non girano quando N56VV è spento.

### Perché funziona

Il chip RTC della motherboard (parte del southbridge/EC) funziona anche a sistema spento, alimentato da un piccolo backup (batteria CMOS o standby). `rtcwake` programma un allarme RTC, e quando scatta, la motherboard riaccende l'alimentazione — esattamente come fa un wake-on-LAN o un wake timer del BIOS.

### Dettaglio tecnico

```bash
# Verifica stato RTC
sudo rtcwake -m show
# o
cat /proc/driver/rtc

# Test rapido (5 minuti di cooling)
sudo rtcwake -m off -s 300
```

Nessun rischio per i filesystem — `rtcwake -m off` fa uno shutdown pulito (acpi poweroff), non un crash. Tutti i servizi systemd si fermano normalmente prima dello spegnimento.

---

## Stats Monitoring System — 2026-06-20

Dopo la simulazione riuscita, è stato aggiunto un sistema di rilevazione statistiche pre/post raffreddamento per il fine-tuning.

### Componenti

| File | Ruolo |
|------|-------|
| `~/.hermes/scripts/cooling-stats.sh` | Cattura snapshot termico/sistema completo |
| `~/.hermes/scripts/cooling-compare.sh` | Confronta log pre e post in formato tabellare |
| `~/.hermes/scripts/cooling-post-report.sh` | Wrapper: cattura post + genera report (usato dal cron) |

### Metriche catturate

- Temperature: CPU Package, Core 0-3, ACPI, HDD (smartctl)
- Ventola: RPM CPU fan
- Sistema: uptime, load average, boot_id, RAM/Swap
- `/proc/stat` sum (per delta attività CPU)

### Job

| Job ID | Nome | Schedule | Script | Modalità |
|--------|------|----------|--------|----------|
| `4290847cf173` (esistente) | `N56VV Nightly Cooling Period` | `0 1 * * *` | `cooling-period.sh` | `no_agent=true` |
| `3d9f08a47adf` (nuovo) | `N56VV Cooling Stats Report` | `10 6 * * *` | `cooling-post-report.sh` | `no_agent=true`, deliver `origin` |

### Flusso notturno

```
01:00 → cooling-period.sh → cooling-stats.sh --pre (salva stats) → rtcwake -m off (spegnimento)
06:00 → RTC riaccende → boot → systemd avvia Hermes
06:10 → cooling-post-report.sh → cooling-stats.sh --post → cooling-compare.sh → report all'utente
```

### Log

Tutti i file in `~/.hermes/cooling-stats/`:
- `YYYY-MM-DD--pre.log` — stats pre-cooling
- `YYYY-MM-DD--post.log` — stats post-cooling

Il report include delta temperature, fan, boot_id verification, e viene consegnato al canale origin ogni mattina alle 06:10.
