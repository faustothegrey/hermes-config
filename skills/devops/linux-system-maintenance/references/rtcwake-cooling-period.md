# rtcwake Cooling Period — Scheduled Shutdown for Thermal Mitigation

## When to use this pattern

The system (especially an old laptop with clogged heatsink) runs dangerously hot under sustained load and a physical fix (cleaning, repaste) isn't immediately possible. A **nightly cooling period** gives the CPU 5+ hours of complete thermal recovery.

## Prerequisites

- `sudo rtcwake` must work without password (`NOPASSWD` in sudoers)
- The kernel RTC driver must be active (`cat /proc/driver/rtc`)
- Hermes cron system must be running (`hermes cron list` shows jobs)
- The target machine should be able to power off and on via ACPI (standard on all modern x86)

## The technique

```bash
# Shutdown immediately, wake up after N seconds
sudo rtcwake -m off -s 18000   # 5 hours

# Alternative: wake at absolute timestamp
sudo rtcwake -m off -t "$(date -d '06:00' +%s)"
```

- `-m off` = clean ACPI poweroff (not a crash — systemd shuts down normally)
- `-s N` = seconds until RTC triggers wake
- RTC chip runs on CMOS battery / standby power — works while system is off
- At wake time, motherboard powers on like a normal boot

## Integration with Hermes cron

Create a `no_agent=true` script:

```bash
# ~/.hermes/scripts/cooling-period.sh
#!/bin/bash
sudo rtcwake -m off -s 18000
```

Then schedule it:

```bash
hermes cron create \
  --name "Nightly Cooling Period" \
  --schedule "0 1 * * *" \
  --no-agent \
  --script cooling-period.sh \
  --deliver local
```

Or via the cronjob tool:
- action=create, name, schedule="0 1 * * *", no_agent=true, script="cooling-period.sh", deliver="local"

### Key characteristics of no_agent scripts

- No LLM overhead — pure shell execution
- Must be a file under `~/.hermes/scripts/`
- Scripts ending in `.sh` run via bash; others run via Python
- `deliver: local` means output goes to disk only, never surfaces in chat
- stdout on success is silently consumed; stderr on failure triggers an alert
- The script executes BEFORE `rtcwake` shuts the system down — the shutdown itself happens inside the script

## Auditing existing cronjobs against a forbidden window

After creating a cooling/shutdown window, check all existing jobs:

1. List all jobs: `cronjob action='list'`
2. For each job, identify its schedule in cron syntax
3. Check if any executions fall inside the forbidden window (e.g. 1:00-6:00)
4. For jobs that overlap:
   - If the job runs on the machine that shuts down → leave it (it simply won't execute while the machine is off)
   - If the job is borderline at wake-up time (e.g. scheduled at 6:00 while wake is at 6:00) → shift it by +1h for margin
5. Non-LLM `no_agent` jobs in the forbidden window are harmless — they won't run because there's no agent/host to run them

## Documentation pattern

After implementing a cooling period, update the system knowledge base:

1. **Specific note** (e.g. `System/Scheduled Restarts.md`): add a compact table with job ID, schedule, script path, and the exact rtcwake command
2. **Comprehensive note** (e.g. `System/fauno-N56VV Stability Monitoring.md`): add a full section with context, implementation details, cronjob specs, why it works (RTC hardware), and verification commands
3. **HOT memory**: a one-liner pointing to the Obsidian notes

## Verification

Before the first nightly run:

```bash
# Check RTC is functional
sudo rtcwake -m show

# Verify the script is executable
ls -la ~/.hermes/scripts/cooling-period.sh

# Check the cronjob exists
hermes cron list | grep -i cooling

# Verify sudo NOPASSWD works
sudo -n true && echo "NOPASSWD OK"
```

After the first run (next day):

```bash
# Check last run time
hermes cron list

# Verify system boot time matches RTC wake
uptime -s

# Check temperatures after cooldown
for z in /sys/class/thermal/thermal_zone*; do
  [ -r "$z/temp" ] || continue
  echo "$(cat $z/type): $(awk \"BEGIN{printf %.1f, $(cat $z/temp)/1000}\") C"
done
```

Expected: CPU idles at 35-55°C after 5h of cooldown, vs 75-80°C before the cooling period was implemented.

## Pitfalls

- `rtcwake -m off` with `-s` specifying seconds from NOW, not from a fixed wall time so if the cron job runs late (e.g. 01:02 instead of 01:00), the wake time shifts by the same amount. Use absolute timestamps with `-t` for precision. In practice, 5h of margin absorbs a few minutes of jitter.
- If the motherboard battery (CMOS) is dead, RTC settings may not persist across full power loss. `rtcwake -m off` still works because the system doesn't fully remove power from the RTC.
- Some very old BIOS implementations don't support RTC wake from S5 (soft-off). Test once manually first: `sudo rtcwake -m off -s 120` (2 minutes) and wait for the system to reboot.
- After wake, systemd services start normally. Jobs scheduled exactly at wake time may run late. Add a 1-hour margin for safety.
- `hermes cron` jobs with `deliver: local` produce no visible output — check via `hermes cron list` or the job's output log on disk.

## Stats monitoring — pre/post thermal data collection

### When to add this

After the cooling period is confirmed working, add measurement so you can fine-tune duration, verify effectiveness, and detect degradation over time.

### Scripts

**`cooling-stats.sh`** — system snapshot, writes to `~/.hermes/cooling-stats/YYYY-MM-DD--{pre,post}.log`

Metrics captured:
- Timestamp, boot_id (changes on reboot), uptime seconds
- CPU Package temp, Core 0-3 temps (from `coretemp` hwmon)
- ACPI temp (from `acpitz` thermal zone)
- HDD temp (from `smartctl -A /dev/sda | grep Temperature_Celsius`)
- CPU fan RPM (from `asus` hwmon)
- Load average, memory (free -h), swap
- `/proc/stat` cpu sum (for delta computation)

**`cooling-compare.sh`** — compares pre/post logs, outputs:

```
 ┌────────────────────┬─────────┬──────────┬────────┐
 │ Metric             │ Pre     │ Post     │ Delta  │
 ├────────────────────┼─────────┬──────────┬────────┤
 │ CPU Package        │    68°C  │    48°C  │ ↓20°C ✓ │
 │ Core 0             │    66°C  │    47°C  │ ↓19°C ✓ │
 │ Core 1             │    68°C  │    48°C  │ ↓20°C ✓ │
 │ ACPI               │      67°C  │      47°C  │ ↓20°C ✓ │
 │ HDD                │      40°C  │      35°C  │   ↓5°C ✓ │
 └────────────────────┴─────────┴──────────┴────────┘
```

Also reports load comparison, uptime, and verifies boot_id changed (confirms actual reboot).

**`cooling-post-report.sh`** — cron entrypoint wrapper:
1. Runs `cooling-stats.sh --post`
2. Runs `cooling-compare.sh`
3. Stdout is delivered by cron (no_agent=true)

### Integration steps

1. **Update cooling-period.sh** — add stats capture before shutdown:
```bash
#!/bin/bash
/home/fausto/.hermes/scripts/cooling-stats.sh --pre
sudo rtcwake -m off -s 18000
```

2. **Schedule post-report job**:
```
cronjob action=create
  name="N56VV Cooling Stats Report"
  schedule="10 6 * * *"
  no_agent=true
  script="cooling-post-report.sh"
  deliver="origin"
```

3. **Create the stats directory**: `mkdir -p ~/.hermes/cooling-stats/`

### Stats file naming

- `~/.hermes/cooling-stats/2026-06-21--pre.log` — captured at 01:00 before shutdown
- `~/.hermes/cooling-stats/2026-06-21--post.log` — captured at 06:10 after wake

If the job runs exactly at 01:00, the log date is the calendar date at that moment (which will be the next day if past midnight).

### What to look for in the nightly report

| Signal | Interpretation |
|--------|---------------|
| CPU Package drops 15-25°C | Cooling period effective |
| CPU Package drops <10°C | Too short, or heatsink so clogged that 5h isn't enough to reach ambient (rare - consider hardware clean) |
| HDD drops <3°C | Normal - HDD has thermal mass and stays warm longer |
| boot_id unchanged | System did NOT actually reboot (rtcwake failure, or job ran but system didn't shut down) |
| Pre temps at 01:00 already low (<50°C) | System was already idling — cooling period may be unnecessary on that particular night |

### Fine-tuning decisions based on data

- If after 5h of cooling the CPU is still above 55°C → **extend duration** (try 6h, -s 21600)
- If CPU drops to 35-40°C after only 3h → **shorten duration** (try 3h, -s 10800, free up 2h for overnight tasks)
- If post-cooling temps return to pre-cooling levels within 1h of wake → the issue is physical (heatsink clogged), adjust expectations
- If pre-cooling temps are consistently low (<55°C at 01:00), consider **disabling the cooling period on low-load days**
