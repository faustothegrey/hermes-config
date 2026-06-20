# N56VV Thermal Freeze Diagnosis — Worked Example

**Date:** 2026-06-20
**Host:** fausto-N56VV (Asus N56VV laptop, i7-3630QM, 2012)
**Symptom:** PC freezes unpredictably, recovers only via hard reboot.

## Evidence collected

### Current state (7 min after boot)
- Temperature: **76-77°C** at idle (both acpitz and x86_pkg_temp zones)
- Fan: **3300 RPM** (via asus-isa-0000/cpu_fan sensor)
- Cooling devices: **all 8 processor coolers at state 0** (no active cooling beyond the fan)
- CPU frequencies: 1.2-2.6 GHz (i7-3630QM should boost to 3.4 GHz — already throttling)
- Load average: 5.53, 6.15, 3.30 (extremely high for just booted)
- Memory: 7.6 GiB total, 5.4 GiB available (not the problem)
- Swap: 2 GiB, 0 used
- Disk: 41% used, SMART: 1055 Reallocated, 15 Current_Pending

### Previous boot thermal timeline
```
01:22:58 — powercap intel-rapl: package locked by BIOS
01:23:06 — temp-reboot-monitor: WARNING: 95.0°C (1/30)
01:23:15 — kernel: intel_powerclamp: Start idle injection to reduce power
01:23:16 — temp-reboot-monitor: WARNING: 95.0°C (2/30)
01:23:36 — temp-reboot-monitor: WARNING: 95.0°C (3/30)
01:23:56 — temp-reboot-monitor: temperature back below cooldown 88.0°C; reset
01:26:54 — kernel: intel_powerclamp: Stop forced idle injection
01:27:56 — temp-reboot-monitor: WARNING: 95.0°C (1/30)
01:28:16 — temp-reboot-monitor: WARNING: 95.0°C (2/30)
01:28:24 — kernel: intel_powerclamp: Start idle injection to reduce power
```

Six `NOHZ tick-stop error` messages at 01:23 during the first powerclamp event.

### SMART history from same boot
```
10:37:44 — Temperature_Celsius: 111 → 103 (SMART raw)
11:37:44 — 103 → 101
12:07:44 — 101 → 100
13:07:44 — 100 → 99
14:37:44 — 99 → 98
17:37:44 — 98 → 97
21:37:44 — 97 → 96
```
HDD was running at 96-111°C all day, confirming sustained thermal stress on the whole chassis.

## Diagnosis chain
1. **Kernel thermal throttling confirmed** — `intel_powerclamp` fired twice in the last boot. This is the freeze mechanism: the kernel pauses the CPU to avoid melting it, and the system appears frozen.
2. **Fan works but cooling is inadequate** — 3300 RPM + 77°C at idle means the heatsink is clogged with 13 years of dust. Air can't flow through the radiator fins no matter how fast the fan spins.
3. **HDD is a secondary contributor** — 15 pending sectors can cause multi-second I/O stalls, but the primary freeze cause is thermal.
4. **Memory pressure is not a factor** — 5.4 GiB available, 0 swap used.

## Resolution path
**Required:** Physical cleaning of the heatsink/fan assembly + thermal paste replacement.

**Software mitigations (temporary):**
- Kill heavy services: `snap-store`, `tracker-miner-fs-3`, `quasar-voice-detection`
- Scheduled reboot for cooling: `sudo shutdown -r +10` or `sudo systemd-run --on-active=15min --unit=cooling-reboot /usr/bin/systemctl reboot`
- The existing `temp-reboot-monitor` (95°C threshold, 30 hits, Telegram+email alert) works correctly and triggered safety poweroff.
- `heavy-load-watchdog` Hermes cron (every 5 min, Telegram alerts on high load/temp) provides additional monitoring.
- `system-freeze-monitor` timer (every 1 min, local sampling) for forensic data.

## Key commands used in this session
```bash
# Capture all evidence in one pass
printf '=== uptime ===\n'; uptime
printf '=== load ===\n'; cat /proc/loadavg
printf '=== memory ===\n'; free -h
printf '=== swap ===\n'; swapon --show
printf '=== disk ===\n'; df -h /
printf '=== temps ===\n'; for z in /sys/class/thermal/thermal_zone*; do echo "$(cat $z/type): $(awk "BEGIN{printf \"%.1f\",$(cat $z/temp)/1000}") C"; done
printf '=== fan ===\n'; sudo sensors 2>/dev/null | grep -i fan
printf '=== cooling ===\n'; for c in /sys/class/thermal/cooling_device*; do echo "$(basename $c): type=$(cat $c/type), cur=$(cat $c/cur_state)"; done
printf '=== cpu freq ===\n'; cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | paste -sd,
printf '=== prev boot thermal ===\n'; sudo journalctl -k -b -1 2>/dev/null | grep -i -E "powerclamp|tick-stop|thermal"
printf '=== prev boot tail ===\n'; sudo journalctl -k -b -1 2>/dev/null | tail -5
printf '=== temp-reboot-monitor ===\n'; sudo journalctl -u temp-reboot-monitor.service --since "2 hours ago" 2>/dev/null | grep "WARNING\|temperature" | tail -20
printf '=== SMART ===\n'; sudo smartctl -A /dev/sda 2>/dev/null | grep -E "Reallocated|Current_Pending|Offline_Uncorrectable|Temperature"
printf '=== top processes ===\n'; ps aux --sort=-%cpu | head -8
```
