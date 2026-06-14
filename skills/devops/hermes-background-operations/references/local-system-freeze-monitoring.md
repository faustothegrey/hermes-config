# Local system freeze monitoring pattern

Use when a Linux desktop/server "freezes" or becomes unresponsive and the user wants evidence before guessing.

## Diagnostic sequence that worked

1. Capture live pressure first, before making changes:
   - uptime/load, `free -h`, `swapon --show`, disk usage, top CPU/RSS processes.
   - thermal zones under `/sys/class/thermal/thermal_zone*/{type,temp}`.
   - failed units via `systemctl --failed` and boot list/journal snippets.
   - `/proc/pressure/{cpu,io,memory}` because PSI often explains freeze-like stalls when memory looks fine.
   - `vmstat 1 5`; `iostat -xz 1 3` if present.
2. Read recent journal for durable signals, not just current symptoms:
   - kernel warnings/errors for current and previous boot.
   - search for: `panic|oops|watchdog|hung task|blocked for more|oom|out of memory|I/O error|ata|ext4|thermal|overheat|mce|hardware error`.
3. Correlate symptoms:
   - High temperature near 95C plus high CPU process => thermal throttling or emergency resets likely.
   - High IO PSI / iowait / `%util` on the system disk => desktop can appear frozen even with free memory.
   - Swap 0 and high MemAvailable => not a memory exhaustion freeze.
4. For a runaway user service, prefer a systemd drop-in over editing the main unit:
   - thread-limit numeric libraries with `OMP_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, `MKL_NUM_THREADS=1`, `NUMEXPR_NUM_THREADS=1`;
   - reduce priority with `Nice=10`;
   - cap sustained CPU with `CPUQuota=60%` or another conservative value;
   - `systemctl --user daemon-reload`, restart, then verify `systemctl --user show ... -p CPUQuotaPerSecUSec -p Nice -p Environment`.
5. Add a lightweight local monitor when the cause is intermittent:
   - use a user systemd timer for local evidence collection when no external notification is needed;
   - log bounded samples under `~/.local/state/<monitor>/samples.log` and alerts under `alerts.log`;
   - include timestamp, host, load, busy/iowait %, max temp, MemAvailable, swap used, PSI metrics, top CPU/RSS process, and the suspicious service command line.

## Alert thresholds used as a starting point

These are intentionally conservative for an old laptop and should be tuned per host:

- temperature >= 90C
- iowait >= 25%
- IO PSI some avg10 >= 20
- load1 >= number of logical CPUs, or a host-specific threshold such as 8 on an 8-thread laptop
- MemAvailable < 512 MiB

## Reporting guidance

Report evidence, not just guesses. Separate likely causes from weaker signals:

- "Most likely" when live metrics and logs agree, e.g. repeated 95-97C temperature warnings plus runaway CPU.
- "Possible" when one metric suggests trouble, e.g. high cumulative disk utilization but no SMART results yet.
- "Less likely" when checked evidence argues against it, e.g. no swap use and ample MemAvailable.

Avoid preserving environment-specific absences as durable facts. If `smartctl` or another tool is missing, capture the next diagnostic step (install/use SMART tooling) rather than a rule that the tool is unavailable.

## Worked session summary

On an Ubuntu 22.04 laptop with Intel i7-3630QM, repeated freezes correlated with:

- thermal-zone readings/warnings near 95-97C;
- a wake-word Python service consuming roughly one or more cores continuously;
- high IO pressure on `/proc/pressure/io` and high disk utilization on the main SATA disk;
- no strong evidence of RAM exhaustion because swap was unused and MemAvailable was several GiB.

Mitigation applied:

- created a user-level systemd timer that samples freeze-relevant metrics every minute;
- added a drop-in to the wake-word service limiting BLAS/OpenMP threads, lowering priority, and adding `CPUQuota=60%`;
- restarted and verified the service, observing fewer tasks and lower immediate CPU/temperature pressure.

Reusable script template: `scripts/system-freeze-monitor.sh`.
