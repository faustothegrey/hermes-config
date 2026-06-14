#!/usr/bin/env bash
# Lightweight heavy-load watchdog for fragile machines.
# Prints one alert when thresholds are sustained/critical; prints nothing otherwise.
# Intended for Hermes cron no_agent=True delivery.
set -u

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/system-watchdogs"
STATE_FILE="$STATE_DIR/heavy-load-watchdog.state"
mkdir -p "$STATE_DIR"

HOST="$(hostname)"
NOW_ISO="$(date -Is)"
NOW_EPOCH="$(date +%s)"

read LOAD1 LOAD5 LOAD15 _ < /proc/loadavg
MEM_AVAIL_KB="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
SWAP_USED_KB="$(awk '/SwapTotal:/ {total=$2} /SwapFree:/ {free=$2} END {print total-free}' /proc/meminfo)"

MAX_TEMP_C="na"
MAX_TEMP_TYPE="na"
for z in /sys/class/thermal/thermal_zone*; do
  [ -r "$z/temp" ] || continue
  type="$(cat "$z/type" 2>/dev/null || basename "$z")"
  case "$type" in x86_pkg_temp|acpitz|coretemp|k10temp) ;; *) continue ;; esac
  raw="$(cat "$z/temp" 2>/dev/null || echo 0)"
  temp_c="$(awk -v t="$raw" 'BEGIN {printf "%.1f", t/1000}')"
  if [ "$MAX_TEMP_C" = "na" ] || awk -v a="$temp_c" -v b="$MAX_TEMP_C" 'BEGIN {exit !(a>b)}'; then
    MAX_TEMP_C="$temp_c"
    MAX_TEMP_TYPE="$type"
  fi
done

PSI_CPU_SOME="$(awk -F'[ =]' '/some/ {print $3}' /proc/pressure/cpu 2>/dev/null || echo 0)"
PSI_IO_SOME="$(awk -F'[ =]' '/some/ {print $3}' /proc/pressure/io 2>/dev/null || echo 0)"
PSI_IO_FULL="$(awk -F'[ =]' '/full/ {print $3}' /proc/pressure/io 2>/dev/null || echo 0)"
PSI_MEM_SOME="$(awk -F'[ =]' '/some/ {print $3}' /proc/pressure/memory 2>/dev/null || echo 0)"

read_cpu() { awk '/^cpu / {print $2,$3,$4,$5,$6,$7,$8}' /proc/stat; }
read u1 n1 s1 i1 w1 irq1 soft1 < <(read_cpu)
sleep 1
read u2 n2 s2 i2 w2 irq2 soft2 < <(read_cpu)
total1=$((u1+n1+s1+i1+w1+irq1+soft1)); total2=$((u2+n2+s2+i2+w2+irq2+soft2)); dt=$((total2-total1)); dw=$((w2-w1)); didle=$((i2-i1))
IOWAIT_PCT="0.0"; BUSY_PCT="0.0"
if [ "$dt" -gt 0 ]; then
  IOWAIT_PCT="$(awk -v a="$dw" -v b="$dt" 'BEGIN {printf "%.1f", 100*a/b}')"
  BUSY_PCT="$(awk -v idle="$didle" -v total="$dt" 'BEGIN {printf "%.1f", 100*(total-idle)/total}')"
fi

TOP_CPU="$(ps -eo pid,comm,pcpu,pmem --sort=-pcpu | awk 'NR==2 {printf "%s %s CPU=%s%% MEM=%s%%", $1,$2,$3,$4}')"
TOP_MEM="$(ps -eo pid,comm,rss,pmem --sort=-rss | awk 'NR==2 {printf "%s %s RSS=%sKB MEM=%s%%", $1,$2,$3,$4}')"

REASONS=()
CRITICAL=0
awk -v v="$LOAD5" 'BEGIN {exit !(v>=6.0)}' && REASONS+=("load5=${LOAD5}")
awk -v v="$IOWAIT_PCT" 'BEGIN {exit !(v>=20.0)}' && REASONS+=("iowait=${IOWAIT_PCT}%")
awk -v v="$PSI_IO_SOME" 'BEGIN {exit !(v>=20.0)}' && REASONS+=("IO pressure=${PSI_IO_SOME}")
awk -v v="$PSI_CPU_SOME" 'BEGIN {exit !(v>=50.0)}' && REASONS+=("CPU pressure=${PSI_CPU_SOME}")
awk -v v="$PSI_MEM_SOME" 'BEGIN {exit !(v>=10.0)}' && REASONS+=("memory pressure=${PSI_MEM_SOME}")
[ "$MEM_AVAIL_KB" -lt 819200 ] && REASONS+=("MemAvailable=${MEM_AVAIL_KB}KB")
if [ "$MAX_TEMP_C" != "na" ]; then
  awk -v v="$MAX_TEMP_C" 'BEGIN {exit !(v>=80.0)}' && REASONS+=("temp=${MAX_TEMP_C}C")
  awk -v v="$MAX_TEMP_C" 'BEGIN {exit !(v>=90.0)}' && CRITICAL=1
fi
awk -v v="$IOWAIT_PCT" 'BEGIN {exit !(v>=30.0)}' && CRITICAL=1
awk -v v="$PSI_IO_FULL" 'BEGIN {exit !(v>=25.0)}' && CRITICAL=1

prev_count=0
last_alert=0
[ -r "$STATE_FILE" ] && . "$STATE_FILE" 2>/dev/null || true

if [ "${#REASONS[@]}" -eq 0 ]; then
  printf 'prev_count=0\nlast_alert=%s\n' "${last_alert:-0}" > "$STATE_FILE"
  exit 0
fi

count=$(( ${prev_count:-0} + 1 ))
printf 'prev_count=%s\nlast_alert=%s\n' "$count" "${last_alert:-0}" > "$STATE_FILE"

if [ "$CRITICAL" -ne 1 ] && [ "$count" -lt 2 ]; then exit 0; fi
if [ "$CRITICAL" -ne 1 ] && [ $((NOW_EPOCH - ${last_alert:-0})) -lt 1800 ]; then exit 0; fi
printf 'prev_count=%s\nlast_alert=%s\n' "$count" "$NOW_EPOCH" > "$STATE_FILE"

cat <<EOF
⚠️ ${HOST}: heavy load / thermal / IO pressure detected (${NOW_ISO})
Reasons: ${REASONS[*]}
State: load=${LOAD1}/${LOAD5}/${LOAD15}, CPU busy=${BUSY_PCT}%, iowait=${IOWAIT_PCT}%, temp=${MAX_TEMP_C}C (${MAX_TEMP_TYPE}), MemAvailable=${MEM_AVAIL_KB}KB, swap_used=${SWAP_USED_KB}KB
PSI: cpu=${PSI_CPU_SOME}, io_some=${PSI_IO_SOME}, io_full=${PSI_IO_FULL}, mem=${PSI_MEM_SOME}
Top CPU: ${TOP_CPU}
Top RAM: ${TOP_MEM}
Note: lightweight /proc/sysfs check only; no long SMART test or disk stress.
EOF
