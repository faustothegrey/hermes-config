# External fan installation — thermal test (2026-06-22)

## Hardware
- Host: fausto-N56VV (Ivy Bridge laptop, ~2013)
- Modification: USB-powered external fan positioned to aid exhaust airflow
- Previous cooling history: thermal freezes at 95°C+, heatsink cleaned + repasted earlier

## Baseline (pre-fan) — 2026-06-22 17:30 CEST
- CPU package: 81°C
- CPU cores: 75-81°C
- Fan (internal): 3300 RPM
- Disk: 52°C
- Load: 0.22 (near-idle)
- AC adapter: unplugged (battery only during recording)

## Control point — 2026-06-21 19:00
- CPU package: 81°C
- CPU cores: 78-81°C
- Fan: 3300 RPM
- Disk: 51°C
- Load: 0.00 (idle)

## Sampling cadence
- Increased from 30-min to 5-min (schedule: `*/5 7-23 * * *`)
- Cron job: `daytime-thermal-snapshot` (job_id: 807d66777982)
- Script: `cooling-stats.sh` (no args = snapshot mode)

## Related cron jobs
- `thermal-analysis-report` (919c3e205f8c) — one-shot at 2026-06-23 23:45, updated to compare pre/post fan data
- `daytime-thermal-snapshot` (807d66777982) — every 5 min during 7-23
- `daytime-thermal-midnight` (c90b8615686d) — 00:00 daily

## Memory/fact reference
- Memory: "N56VV freeze = thermal overload (CPU 95°C+). Fix: pulizia heatsink/fan, repaste, + ventola USB esterna installata 22-Giu-2026."
- Fact #26: "External USB fan installed on N56VV on 2026-06-22 ~17:30"