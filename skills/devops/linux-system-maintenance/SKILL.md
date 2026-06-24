---
name: linux-system-maintenance
description: "Diagnose and safely clean up Linux system health issues: load/RAM/disk/temperature, failed systemd units, package/service removal, and USB storage detection."
tags:
  - linux
  - systemd
  - apt
  - usb-storage
  - health-check
---

# Linux system maintenance

Use this when the user asks whether the machine is stable, wants failed services removed, wants unwanted packages cleaned up, or needs to know whether an external USB disk is detected.

## Operating principles

1. Verify live state with tools before answering. Do not infer system state from memory.
2. Keep the user-facing answer practical: stable / not stable, what is risky, and what was changed.
3. For destructive cleanup, distinguish between the failing component and related components that may still be useful. Prefer removing the narrow problematic install/source first.
4. After removing packages/services, verify with commands that prove the unit/package/binary/path is gone.
5. Avoid stressful disk operations on machines with known SMART risk unless the user explicitly asks.

## System health quick check

Collect a compact snapshot:

```bash
printf '=== date ===\n'; date
printf '\n=== uptime/load ===\n'; uptime
printf '\n=== memory ===\n'; free -h
printf '\n=== disk ===\n'; df -h / /home 2>/dev/null || df -h
printf '\n=== pressure stall ===\n'; for f in /proc/pressure/{cpu,io,memory}; do echo "$f"; cat "$f"; done
printf '\n=== thermal zones ===\n'; for z in /sys/class/thermal/thermal_zone*; do [ -r "$z/temp" ] || continue; printf '%s %s %.1f C\n' "$(basename "$z")" "$(cat "$z/type" 2>/dev/null)" "$(awk "BEGIN{print $(cat "$z/temp")/1000}")"; done
printf '\n=== failed units ===\n'; systemctl --failed --no-pager || true
printf '\n=== recent warnings ===\n'; journalctl -p warning..alert -n 40 --no-pager 2>/dev/null || true
```

If `smartctl` is available and a known-risk disk is involved, use only quick SMART reads, not long tests:

```bash
sudo -n smartctl -H -A /dev/sda 2>/dev/null | sed -n '1,120p'
```

## Removing or permanently disabling an unwanted service safely

Use this for services the user no longer wants because they are noisy, resource-heavy, or failed. Prefer the narrowest permanent disable that stops automatic restarts without deleting the underlying project unless the user explicitly asks for deletion.

For user-level systemd units (`systemctl --user ...`):

```bash
systemctl --user stop UNIT 2>/dev/null || true
systemctl --user disable UNIT
systemctl --user reset-failed UNIT 2>/dev/null || true
systemctl --user daemon-reload
systemctl --user is-enabled UNIT 2>&1 || true
systemctl --user is-active UNIT 2>&1 || true
```

If the user asks for a permanent disable and `systemctl --user mask UNIT` fails because the unit file already exists in `~/.config/systemd/user/`, move the unit file aside instead of fighting systemd:

```bash
unit="$HOME/.config/systemd/user/UNIT"
backup="$HOME/.config/systemd/user/UNIT.disabled"
[ -e "$unit" ] && mv "$unit" "$backup"
systemctl --user daemon-reload
systemctl --user is-enabled UNIT 2>&1 || true   # should report missing/no such file
systemctl --user is-active UNIT 2>&1 || true    # should be inactive
```

Verify with a targeted process check and report the backup path so the user can restore it later.

## Removing a failed service/package safely

1. Identify the exact source of the failed unit:

```bash
systemctl status UNIT --no-pager -l
systemctl list-unit-files --no-pager | awk '/PATTERN/{print}'
dpkg -l | awk '$2 ~ /PATTERN/ {print $1,$2,$3}'
snap list 2>/dev/null | awk '/PATTERN/{print}'
snap services PACKAGE 2>/dev/null || true
```

2. Stop/disable/reset failed state before uninstalling:

```bash
sudo -n systemctl stop UNIT 2>/dev/null || true
sudo -n systemctl disable UNIT 2>/dev/null || true
sudo -n systemctl reset-failed UNIT 2>/dev/null || true
```

3. Remove the correct package source:
   - apt package: `sudo -n apt-get purge -y PKG... && sudo -n apt-get autoremove -y --purge`
   - snap package/service: `sudo -n snap stop --disable SNAP.SERVICE 2>/dev/null || true; sudo -n snap remove SNAP`

4. Verify:

```bash
command -v BINARY || echo 'binary assente'
dpkg -l | awk '$2 ~ /PATTERN/ {print $1,$2,$3}'
snap list PACKAGE 2>/dev/null || echo 'snap package assente'
systemctl list-unit-files --no-pager | awk '/PATTERN/{print}'
systemctl --failed --no-pager || true
```

## Kubernetes cleanup pattern

When the user explicitly asks to remove Kubernetes, remove kube-specific packages and state, but do not automatically remove Docker/containerd unless asked because they may be used independently.

```bash
sudo -n systemctl stop kubelet 2>/dev/null || true
sudo -n systemctl disable kubelet 2>/dev/null || true
sudo -n systemctl reset-failed kubelet 2>/dev/null || true
sudo -n apt-get purge -y kubelet kubeadm kubectl kubernetes-cni cri-tools
sudo -n apt-get autoremove -y --purge
sudo -n rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /etc/cni /opt/cni /var/lib/cni /var/run/kubernetes /run/kubernetes
rm -rf "$HOME/.kube"
```

Verify `kubelet`, `kubeadm`, `kubectl`, and `crictl` are absent and no kube systemd units remain.

## Snap duplicate cleanup pattern

If a failed service belongs to a snap, check whether an apt version of the same app exists. If yes, removing only the snap can be the safer cleanup because the desktop app remains available from apt.

Example: failed `snap.remmina.ssh-agent.service` can be resolved by removing the Remmina snap while leaving apt Remmina installed.

## USB external disk detection

Use this sequence when a user expects an external disk to be connected:

```bash
lsblk -o NAME,TYPE,SIZE,MODEL,SERIAL,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
lsusb
lsusb -t
find /dev/disk/by-id -maxdepth 1 -type l -iname '*usb*' -printf '%f -> %l\n' 2>/dev/null | sort || true
journalctl -k --since '5 minutes ago' --no-pager | grep -Ei 'usb|uas|usb-storage|scsi|sd[a-z]|blk|ntfs|exfat|ext4|i/o error|reset|disconnect|device descriptor|over-current|power' || true
```

Interpretation:
- If no `lsusb` entry, no `/dev/sdX`, no `/dev/disk/by-id/*usb*`, and no kernel USB/storage logs after reconnect, Linux is not seeing the device at the USB layer. Treat it as likely cable/port/power/enclosure/device hardware, not a mount/filesystem issue.
- If USB enumerates but no block device appears, investigate UAS/usb-storage errors and enclosure compatibility.
- If block device appears but is unmounted, then inspect filesystem and mount state.

See `references/2026-06-13-system-cleanup-usb-disk.md` for a concrete session transcript pattern.

## Alert/watchdog notification style

When maintaining local health watchdogs that send system-load alerts, keep notifications concise and action-oriented. If the user asks to reduce noise, emit only the anomalous metric(s) that crossed thresholds (the reasons list), not a full system snapshot, top-process list, or unrelated stats. Full diagnostics can remain in logs or be gathered on demand.

## Persistent anomaly log

The `heavy_load_watchdog.sh` now writes structured **start/resolve** events to
`~/.hermes/anomalies/anomalies.jsonl` so every anomaly is persisted for later query:

```
start  → {"event":"start","id":"20260620_181111","ts":"...","reasons":"IO pressure=28.25","critical":0}
resolve→ {"event":"resolve","id":"20260620_181111","ts":"...","duration_min":6}
```

When the user asks "anomalia ancora in corso?" or "quali anomalie ci sono state?":
1. Read the anomaly log for recent start/resolve pairs
2. Check the watchdog state file (`heavy-load-watchdog.state`) — if `prev_count > 0`, an anomaly is active *now*
3. Check fact_store for stored anomaly records
4. Verify live system metrics for confirmation

Log notable resolved anomalies to fact_store so WARM memory catches them without file I/O.

See `references/anomaly-logging.md` for the full implementation: state file fields, threshold table, integration points in the watchdog script, and the three injection points (start/resolve/setup).

## Proactive thermal mitigation — rtcwake cooling period

When the system (especially an old laptop) runs dangerously hot under sustained load and a physical fix isn't immediately possible, schedule a nightly cooling period: shut down for several hours using `rtcwake -m off` so the CPU gets complete thermal recovery.

### Quick recipe

```bash
# Shutdown now, wake after 5 hours
sudo rtcwake -m off -s 18000
```

### Hermes cron integration pattern

1. Create `~/.hermes/scripts/cooling-period.sh` with the rtcwake command
2. Schedule with `no_agent=true` via `hermes cron create --schedule "0 1 * * *" --no-agent --script cooling-period.sh`
3. Audit existing cronjobs against the forbidden window (1:00-6:00) — see cron conflict checklist below
4. Move borderline jobs (+1h after wake time for margin)
5. Document in Obsidian vault

**Cron job script path pitfall**: When creating a cron job with a script (`script=...`), use only the **filename** (relative to `~/.hermes/scripts/`), NOT an absolute path. The cron tool rejects absolute or home-relative paths.

### Dual cooling periods pattern

When one nightly cooling window is insufficient and a **daytime cooling period** is also needed (e.g. the system stays above 80°C for 14+ consecutive hours), set up two separate rtcwake scripts and cron jobs:

1. **Notturno** (short, e.g. 2h at 02:00-04:00) — just enough to reset the thermal baseline, frees overnight hours for work
2. **Diurno** (longer, e.g. 4h at 12:00-16:00) — covers the peak ambient heat of the afternoon

Implementation steps:

1. **Create two scripts** in `~/.hermes/scripts/`:
   - `cooling-period.sh` — rtcwake with short duration (e.g. `-s 7200` for 2h)
   - `cooling-period-diurno.sh` — rtcwake with longer duration (e.g. `-s 14400` for 4h), calls `cooling-stats.sh --pre-diurno` before shutdown

2. **Create two cron jobs** with `no_agent=true`:
   - Nightly: `schedule="0 2 * * *"` (02:00 shutdown, wake at 04:00)
   - Diurnal: `schedule="0 12 * * *"` (12:00 shutdown, wake at 16:00)

3. **Extend cooling-stats.sh** to support `--pre-diurno`/`--post-diurno` suffixed log files (same metrics, different log filename suffix)

4. **Create per-period report scripts**:
   - `cooling-compare-diurno.sh` — reads `pre-diurno`/`post-diurno` logs, identical format to the nightly compare
   - `cooling-post-report-diurno.sh` — wrapper that captures post-diurno stats then runs the diurno compare

5. **Create separate report cron jobs** for each period:
   - Nightly report: `schedule="10 4 * * *"` (04:10, after 02:00-04:00 cooling)
   - Diurnal report: `schedule="10 16 * * *"` (16:10, after 12:00-16:00 cooling)

### Cron conflict checklist for dual cooling

When implementing two cooling windows, systematically audit every existing cron job. Use this table format:

| Cron job | Schedule | Falls in cooling window? | Action |
|---|---|---|---|
| N56VV Nightly Cooling | `0 1 * * *` | Yes (old) | Move to `0 2 * * *` |
| Research Loop | `0 14 * * *` | Yes (14:00 in 12:00-16:00) | Move to `0 11 * * *` or `0 16 * * *` |
| Stats snapshot | `*/5 7-23 * * *` | Partially (12-16) | Extend range to `*/5 4-12,16-23,0-2 * * *` |
| Heartbeat, watchdog, backup | varies | Falls when machine is off | Leave — cron simply won't fire, no harm |

Rules:
- **Jobs that run on the same machine that shuts down** — leaving them in a cooling window is harmless; they simply don't fire while the machine is off. No queue buildup (standard cron, not anacron).
- **Jobs borderline at wake-up time** — shift by at least +5 min to avoid startup race. `+10 min` is safer.
- **Thermal snapshot range must match wake hours** — if the machine is off 12:00-16:00 and 02:00-04:00, the snapshot range must be `4-12,16-23,0-2` (or equivalent).
- **Research loops, report generators** — these have real work to do; move them to timeslots just before or just after the cooling windows so they don't miss runs.

See `references/rtcwake-cooling-period.md` for the full pattern: prerequisites, no_agent script setup, cronjob auditing procedure, Obsidian documentation template, verification steps, and known pitfalls.

### Thermal stats monitoring (pre/post comparison)

For fine-tuning the cooling period (duration, effectiveness, edge cases), add pre/post metrics capture:

**Architecture**: three scripts form a pipeline:
- `cooling-stats.sh [--pre|--post|--pre-diurno|--post-diurno]` — captures snapshot of CPU temp (package + per-core), ACPI temp, HDD temp (smartctl), fan RPM, load, memory, uptime, boot_id. Writes to `~/.hermes/cooling-stats/YYYY-MM-DD--{pre,post,pre-diurno,post-diurno}.log`
- `cooling-stats.sh` (no flags) — **snapshot mode**: writes to `~/.hermes/cooling-stats/YYYY-MM-DD--snapshot-HHMMSS.log`. Used for daytime periodic sampling.
- `cooling-compare.sh` / `cooling-compare-diurno.sh` — reads today's pre and post logs for one cooling cycle, produces a delta table with ↓↑ arrows per metric, checks boot_id to confirm reboot happened
- `cooling-post-report.sh` / `cooling-post-report-diurno.sh` — wrappers that run post capture then compare (used as cron scripts)

**Supported modes** (cooling-stats.sh):
- `--pre` — saves as `pre.log` (nightly cooling)
- `--post` — saves as `post.log` (nightly cooling)
- `--pre-diurno` — saves as `pre-diurno.log` (diurnal cooling)
- `--post-diurno` — saves as `post-diurno.log` (diurnal cooling)

This lets you run up to two independent cooling cycles per day, each with its own measurement set.

**Integration for a single nightly cooling period**:
1. Update `cooling-period.sh` to call `cooling-stats.sh --pre` before `sudo rtcwake`
2. Create a new cron job at 06:10 (10 min after wake): `cooling-post-report.sh` with `no_agent=true, deliver=origin`

**Integration for dual cooling periods** (notturno + diurno):
1. Create `cooling-period.sh` → calls `--pre`, rtcwake 7200s (02:00-04:00)
2. Create `cooling-period-diurno.sh` → calls `--pre-diurno`, rtcwake 14400s (12:00-16:00)
3. Create report cron: `10 4 * * *` → script `cooling-post-report.sh` (notturno)
4. Create report cron: `10 16 * * *` → script `cooling-post-report-diurno.sh` (diurno)

The report arrives at origin every morning and afternoon and shows exactly how much each temperature component dropped during the cooling window. See `references/rtcwake-cooling-period.md` for full scripts structure, cron conflict checklist methodology (see "Dual cooling periods pattern" section above), and pitfalls.

### Daytime thermal profiling

When the user wants to **decide whether additional cooling periods are needed during the day**, collect a dense temperature profile over several days before making recommendations. This is a data-first approach — "con criterio".

**Workflow**:

1. **Set up periodic snapshot sampling** during waking hours (07:00–00:00) via cron jobs:
   - Main job: every 30 min (07:00–23:30) → ~34 samples/day
   - Midnight snapshot (00:00) → 1 sample/day
   - Existing pre/post (01:00/06:10) → 2 samples/day
   - **Total**: ~37 data points/day

   Create via `cronjob` tool with `no_agent=true` and `script="cooling-stats.sh"` (filename only, no path):
   ```
   action=create, name=daytime-thermal-snapshot, schedule=0,30 7-23 * * *, no_agent=true, script=cooling-stats.sh
   action=create, name=daytime-thermal-midnight, schedule=0 0 * * *, no_agent=true, script=cooling-stats.sh
   ```

2. **Collect for 2-3 days** to establish a meaningful profile (covers weekdays, different workloads).

3. **Analyze the data**:
   - Read all snapshot files from `~/.hermes/cooling-stats/`
   - Identify peak hours, average temps, correlation with load
   - Compare against thermal thresholds (see reference table below)
   - Generate a daily profile: which hours approach 80-85°C+

4. **Decide with the user**:
   - Is a single midday cool-off (e.g., 30-60 min at lunch) enough?
   - Are multiple windows needed (e.g., 14:00 and 19:00)?
   - Can the gap be closed with lighter workload scheduling instead?

5. **Once cool-off windows are decided, schedule them** using the same rtcwake pattern as the nightly period (but shorter durations, e.g. 600-1800s for 10-30 min). For full dual-cooling setup with two daily windows + per-period thermal reports + cron conflict audit, see the **"Dual cooling periods pattern"** section above and `references/rtcwake-cooling-period.md`.

**Pitfalls**:
- Do not skip the collection phase — making cool-off decisions without data leads to either overheating or unnecessary downtime.
- On machines that already run at 80°C+ at partial load, do not wait 3 days; start conservatively with one midday cool-off and refine.
- Snapshot mode produces files, not console output — check `~/.hermes/cooling-stats/` for results.
- Cron jobs with `no_agent=true` are silent on completion (no delivery to chat); this is correct for monitoring — the data piles up in the stats directory.

### Verifying a cooling modification

When the user installs a physical cooling improvement (external fan, heatsink cleaning, thermal paste, undervolt, fan curve change), use this workflow to detect whether it made a tangible difference.

**Immediate actions upon installation:**

1. **Capture a pre-modification baseline**: read the most recent `cooling-stats.sh` snapshot from `~/.hermes/cooling-stats/` that matches the current load level (idle vs busy). Record CPU pkg temp, fan RPM, and disk temp in memory + fact_store so future sessions can reference it.

2. **Find a control point** from a previous day: look for a snapshot at the same time-of-day with similar load from an earlier date. A simple `ls ~/.hermes/cooling-stats/ | grep "YYYY-MM-DD--snapshot-HH"` can confirm whether yesterday's data exists at the comparable timestamp.

3. **Update any scheduled analysis jobs** that will report on the affected period. For example, if there's a `thermal-analysis-report` cron job scheduled, update its prompt to include the pre-modification baseline and ask for an explicit pre/post comparison. This ensures the next automated report mentions the delta.

4. **Increase temporal resolution**: bump the daytime sampling from every 30 min to **every 5 min** (schedule `*/5 7-23 * * *`). The cooling-stats.sh script is lightweight (sysfs reads + one smartctl) — running it every 5 min has negligible system impact. Keep the higher rate for at least 24-48 hours, then restore the original 30-min cadence.

**Interpreting the results:**

- **Same-time-of-day, same-load** comparison is the most reliable signal. Idle temps on an old laptop are very consistent day-to-day (N56VV shows 81°C ±1°C at idle every day) — any deviation beyond ±1-2°C at idle is real.
- Under load, a 3-8°C drop is a tangible win even if it doesn't look dramatic. Every degree below 85°C means more headroom before thermal throttling (95°C+).
- If you only have post-mod data and the user asks for a verdict before 24h, provide the best available comparison (yesterday's same-time snapshot) with appropriate caveats about load differences.
- If the fan was the fix for repeated thermal freezes, also monitor the anomaly log (`~/.hermes/anomalies/anomalies.jsonl`) for reduced frequency of thermal/I/O-pressure events.

**Restoration plan:**
After 48 hours, ask the user whether to keep 5-min sampling (if the fan is proving effective and they want fine-grained data) or restore the original 30-min cadence. If restoring, update the cron schedule back: `0,30 7-23 * * *`.

## Post-crash freeze diagnosis (after reboot)

Use this when the user reports the system froze/hung and was rebooted, and wants to know why. Collect evidence from the **previous boot** before checking current state.

### 1. Determine what happened on the previous boot

```bash
# Kernel logs from previous boot (most important)
sudo journalctl -k -b -1 --no-pager | grep -i -E "(powerclamp|thermal|temp|critical|watchdog|hung_task|lockup|oom|panic|nohz tick-stop)"

# Full tail of previous boot kernel log (last 40 lines)
sudo journalctl -k -b -1 --no-pager | tail -40

# Whether the previous boot ended gracefully or crashed
sudo journalctl -b -1 --no-pager | grep -i -E "poweroff|shutdown|reboot|crash|panic|freeze" | tail -10

# List all boots to see if there was an unclean shutdown
sudo journalctl --list-boots 2>/dev/null | tail -5
```

### 2. Distinguish thermal throttling from I/O stalls from OOM

**Thermal-induced freeze** (most common on old laptops):

```bash
# Markers of kernel thermal throttling in previous boot
sudo journalctl -k -b -1 --no-pager | grep -i "intel_powerclamp"
# "Start idle injection to reduce power" = CPU being force-idled to prevent damage
# "Stop forced idle injection" = temperature dropped back down

# NOHZ tick-stop errors often accompany thermal stress
sudo journalctl -k -b -1 --no-pager | grep -i "tick-stop error"

# Check temperature history from monitoring services
sudo journalctl -u temp-reboot-monitor.service --since "2 hours ago" --no-pager 2>/dev/null | grep -i "WARNING\|temperature"
```

Interpretation:
- `intel_powerclamp: Start idle injection` → kernel forced CPU to idle for thermal safety. The system may appear frozen because the CPU is being deliberately paused. This is the most reliable freeze signature.
- `NOHZ tick-stop error` → accompanies severe thermal stress; the timer subsystem is struggling.
- 95-105°C at time of freeze → almost certainly thermal, especially on a laptop >5 years old.
- No thermal markers but 100% iowait/IO pressure → suspect failing disk.

**I/O-induced stall** (failing HDD, many pending sectors):

```bash
# SMART data (quick check only, no long tests)
sudo smartctl -A /dev/sda | grep -E "Reallocated|Current_Pending|Offline_Uncorrectable|UDMA_CRC|Power_On_Hours|Temperature"

# IO pressure from previous boot
sudo journalctl -b -1 --no-pager | grep -i "iowait\|io pressure\|hung_task"

# If Reallocated_Sector_Ct > 100 or Current_Pending_Sector > 0, HDD is degrading
```

Interpretation:
- Current_Pending_Sector > 0 → disk will hang for seconds reading bad areas
- Reallocated_Sector_Ct > 500 → drive is actively failing
- Combine with iowait ≥25% or IO pressure full ≥20

**OOM / memory pressure**:

```bash
sudo journalctl -k -b -1 --no-pager | grep -i "oom\|out of memory\|killed process"
free -h   # check current swap usage
```

### 3. Check current cooling health

```bash
# Current temperatures
for z in /sys/class/thermal/thermal_zone*; do
  [ -r "$z/temp" ] || continue
  echo "$(cat $z/type 2>/dev/null): $(awk "BEGIN{printf \"%.1f\", $(cat $z/temp)/1000}") C"
done

# Fan speed via sensors
sudo sensors 2>/dev/null | grep -i "fan\|cpu_fan"

# Cooling device states (0 = not cooling, >0 = cooling active)
for c in /sys/class/thermal/cooling_device*; do
  echo "$(basename $c): type=$(cat $c/type 2>/dev/null), cur=$(cat $c/cur_state 2>/dev/null)"
done
```

If fan is spinning (2000+ RPM) but temps are 75-80°C at idle, the **heatsink is clogged with dust** — no software fix, needs physical cleaning.

### 4. Thermal threshold reference (Ivy Bridge / Haswell era laptops)

| Range | Meaning |
|-------|---------|
| 35-55°C | Normal idle |
| 55-75°C | Normal under moderate load |
| 75-85°C | Warm but acceptable |
| 85-90°C | Warning — sustained use not recommended |
| 90-95°C | Thermal throttling likely imminent |
| 95-105°C | Critical — freeze/shutdown expected |

TJunction (absolute max) for common mobile i5/i7 from 2010-2015: typically 100-105°C.

### 5. If temp-reboot-monitor is present

Check its configuration and recent activity:

```bash
systemctl status temp-reboot-monitor.service --no-pager 2>/dev/null || true
cat /etc/temp-reboot-monitor.conf 2>/dev/null | grep -E "REBOOT_AT_C|CONSECUTIVE_HITS|DRY_RUN"
journalctl -u temp-reboot-monitor.service --since "1 hour ago" --no-pager 2>/dev/null | tail -20
```

Default safety pattern: if temperature stays ≥REBOOT_AT_C for N consecutive checks, schedule a delayed poweroff.

See `references/2026-06-20-N56VV-thermal-freeze-diagnosis.md` for a concrete worked example.

## Pitfalls

- `apt autoremove` may remove packages that are only indirectly related because apt marks them auto-installed. Mention notable removals in the final summary.
- `systemctl --failed` only shows currently failed units; still check package/binary/path state after cleanup.
- Do not claim a USB disk has a filesystem problem until the device is visible as USB/block storage.
- `dmesg` may be permission-denied for non-root users; use `journalctl -k` first.
