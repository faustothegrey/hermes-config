# Heavy load + fragile disk watchdog pattern

Use when a user reports freezes on an older Linux machine and a degraded HDD/SSD is suspected or confirmed. Goal: keep an eye on thermal/load/IO pressure without worsening disk health.

## When to use

- SMART attributes show `Current_Pending_Sector > 0`, many reallocated sectors, or very high power-on hours.
- User cannot replace hardware immediately.
- User explicitly wants monitoring/alerts but is worried that a long diagnostic check may make the drive worse.

## Operational policy

1. Avoid invasive disk checks unless the user explicitly consents:
   - avoid `smartctl -t long`, `badblocks`, repeated full-disk reads, forced `fsck` on mounted filesystems, and synthetic IO stress;
   - prefer lightweight reads: `/proc/pressure/*`, `/proc/stat`, `ps`, thermal sysfs, bounded `smartctl -A`.
2. Watch symptoms that predict freeze risk:
   - sustained load average;
   - iowait percentage;
   - PSI IO `some`/`full` averages;
   - CPU thermal zones;
   - low memory/swap pressure;
   - top CPU/RAM processes.
3. For Telegram alerts, use a script-only Hermes cron job (`no_agent=True`) so empty stdout is silent and non-empty stdout is the exact alert.
4. Add anti-spam state:
   - require 2 consecutive bad checks for non-critical conditions;
   - cooldown non-critical alerts for ~30 minutes;
   - let critical conditions alert immediately.
5. Phrase the alert so the user knows it is light-touch monitoring, not a disk test.

## Suggested thresholds for an old 8-thread laptop

Tune per host, but these worked as conservative initial defaults:

- `load5 >= 6.0`
- `iowait >= 20%`
- `IO PSI some >= 20`
- `CPU PSI some >= 50`
- `memory PSI some >= 10`
- `MemAvailable < 800 MiB`
- `temp >= 80C`

Critical immediate-alert examples:

- `temp >= 90C`
- `iowait >= 30%`
- `IO PSI full >= 25`

## Hermes cron shape

```python
cronjob(
    action="create",
    name="heavy-load-watchdog",
    schedule="every 5m",
    script="heavy_load_watchdog.sh",
    no_agent=True,
    deliver="telegram",
    prompt="Lightweight local watchdog. Run the script and deliver stdout only when it emits an alert. Avoid long SMART tests or disk stress.",
)
```

`script` paths are relative to `~/.hermes/scripts/`.

## SMART interpretation caution

`SMART overall-health self-assessment: PASSED` does not mean the disk is healthy. Pending sectors and large reallocated counts can still cause long read stalls and freeze-like desktop hangs.

Report examples:

- `Current_Pending_Sector > 0` = reads are currently unreliable; prioritize backup and avoid stress.
- `Reallocated_Sector_Ct` high = the disk has already remapped failing areas.
- `UDMA_CRC_Error_Count` high = could indicate cable/controller transfer errors rather than media failure.

## User-facing guidance

Say clearly:

- monitoring is lightweight and mostly reads `/proc`/sysfs;
- no SMART long test or disk stress is being run;
- backup/replacement is still the real fix, but monitoring can reduce surprise until hardware is possible.
