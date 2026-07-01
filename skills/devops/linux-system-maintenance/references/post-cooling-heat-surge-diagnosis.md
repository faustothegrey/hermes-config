# Post-Cooling Heat Surge Diagnosis — N56VV Case Study

## Scenario

The N56VV laptop (Ivy Bridge i7, 8GB RAM, WD10JPVX HDD with 73k power-on hours) goes through a nightly cooling period (rtcwake shutdown 02:00-03:00). After waking at 03:00, CPU temperature spikes from 74°C (post-cooling) to 94°C within 65 minutes — undoing the entire cooling benefit.

## Data collected

### Anomaly log (`~/.hermes/anomalies/anomalies.jsonl`)

```jsonl
{"event":"start","id":"20260701_003111","ts":"2026-07-01T00:31:10+02:00","host":"fausto-N56VV","reasons":"iowait=30.9%,IO pressure=20.19","critical":1}
{"event":"resolve","id":"20260701_003111","ts":"2026-07-01T00:37:10+02:00","duration_min":6}
{"event":"start","id":"20260701_031208","ts":"2026-07-01T03:12:07+02:00","host":"fausto-N56VV","reasons":"iowait=28.2%,IO pressure=37.34","critical":1}
{"event":"resolve","id":"20260701_031208","ts":"2026-07-01T04:06:21+02:00","duration_min":54}
{"event":"start","id":"20260701_041225","ts":"2026-07-01T04:12:24+02:00","host":"fausto-N56VV","reasons":"IO pressure=25.32","critical":0}
```

Key observations:
- Anomaly at 00:31 (6 min): brief high-I/O before cooling period
- Anomaly at 03:12 (54 min sustained!): triggered 11 min after wake, persisted for nearly 1 hour
- Anomaly at 04:12: another brief IO pressure spike

### Temperature timeline from cooling-stats snapshots

| File | Timestamp vs wake | Uptime | CPU pkg temp | ACPI temp | Fan RPM | Load |
|------|-------------------|--------|-------------|-----------|---------|------|
| `--post.log` | +9 min | 9 min | **74°C** | 70°C | 3400 | 2.64 |
| `--snapshot-033511.log` | +34 min | 34 min | **91°C** ⚠ | 92°C | 3700 | 7.00 |
| `--snapshot-041525.log` | +65 min | 1h14m | **94°C** 🔴 | 92°C | 3800 | 6.23 |

### Cooling stats (pre/post comparison)

- **Pre-cooling** (02:00, after 10h work): CPU 81°C, HDD 53°C, boot_id `a4b9...`
- **Post-cooling** (03:10, after 1h shutdown): CPU 74°C, HDD 44°C, boot_id `82b1...` ✓ (different boot_id confirms reboot)
- **Delta**: CPU ↓7°C, HDD ↓9°C — cooling period worked correctly, but only 25 minutes of headroom remained

### Scripts and cron jobs involved

| Script | How often called | What it does | I/O cost |
|--------|-----------------|-------------|----------|
| `cooling-stats.sh` | Every 5 min via daytime-thermal-snapshot | Reads sysfs temps, ACPI, fan + **smartctl** | **~0.2s blocking ATA I/O per call** |
| `cooling-post-report.sh` | Once at 03:10 | Calls `cooling-stats.sh --post` then `cooling-compare.sh` | Another smartctl |
| `faro-monitor.sh` | Every 5 min | Peer health check + **smartctl** | Another smartctl |
| `guardiano-watchdog.sh` | Every 2 min | SSH guard check | Light (curl) |
| `heavy-load-watchdog.sh` | Every 5 min | PSI/temp/iowait check | Light (/proc reads) |

Total smartctl calls: at least 2 per 5-min cycle (cooling-stats + faro-monitor), sometimes 3 (with post-report overlapping). On an old WD10JPVX HDD, each ATA SMART read prevents the disk from idling and contributes to IO pressure.

## Root cause

1. **rtcwake cooling period works correctly** — 1h shutdown drops CPU by 7°C, HDD by 9°C
2. **Immediately after wake (03:01)**, all cron jobs fire simultaneously:
   - guardiano-watchdog every 2 min
   - faro-monitor every 5 min (including smartctl)
   - daytime-thermal-snapshot every 5 min (including smartctl)  
   - heavy-load-watchdog every 5 min
   - cooling-post-report at 03:10 (including smartctl)
   - Quest advancement at 04:01 (LLM reading Obsidian vault + web calls)
3. **The old HDD cannot sustain this frequency of SMART reads** — ATA commands keep the disk busy, causing sustained iowait (28%) and IO pressure (37)
4. **CPU stays in high iowait** → generates heat → fan at max (3800 RPM) cannot keep up → 94°C within 65 min

## Fix applied

1. **Removed `smartctl -A /dev/sda` from `cooling-stats.sh`** — set `DISK_TEMP="N/A"` with a comment explaining that this old WD HDD doesn't expose temperature via sysfs, and smartctl is too I/O-heavy for frequent calls
2. **Reduced `daytime-thermal-snapshot` frequency** from `*/5` to `*/30` — 2 snapshots/hour instead of 12, cutting smartctl calls from ~96 to ~16 per work window

## Lessons for future diagnoses

- When investigating post-cooling heat surge, always check the **frequency of smartctl calls** first — it's the #1 I/O offender on old spinning disks
- A 54-minute anomaly duration often means multiple overlapping monitoring scripts, not one sustained event — the watchdog resets every 5 min and keeps re-triggering
- The boot storm (all cron jobs firing within 10 min of wake) is a known pattern — stagger scripts when possible, or accept that the first 15-20 min after wake are always high-I/O
- The old N56VV's fan at 3400-3800 RPM is at its noise/thermal limit — any additional I/O load shows up immediately as temperature increase
