#!/usr/bin/env bash
# Lightweight local freeze monitor for Linux hosts.
# Intended to be run from a systemd timer every 60s.
set -u

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/system-freeze-monitor"
SAMPLE_LOG="$STATE_DIR/samples.log"
ALERT_LOG="$STATE_DIR/alerts.log"
mkdir -p "$STATE_DIR"

now="$(date -Is)"
host="$(hostname)"
uptime_line="$(uptime | sed 's/^ *//')"
load1="$(awk '{print $1}' /proc/loadavg)"
mem_avail_kb="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
swap_used_kb="$(awk '/SwapTotal:/ {total=$2} /SwapFree:/ {free=$2} END {print total-free}' /proc/meminfo)"

max_temp_c="na"
max_temp_type="na"
for z in /sys/class/thermal/thermal_zone*; do
  [ -r "$z/temp" ] || continue
  temp_raw="$(cat "$z/temp" 2>/dev/null || echo 0)"
  type="$(cat "$z/type" 2>/dev/null || basename "$z")"
  temp_c="$(awk -v t="$temp_raw" 'BEGIN {printf "%.1f", t/1000}')"
  if [ "$max_temp_c" = "na" ] || awk -v a="$temp_c" -v b="$max_temp_c" 'BEGIN {exit !(a>b)}'; then
    max_temp_c="$temp_c"
    max_temp_type="$type"
  fi
done

cpu_psi_some="$(awk -F'[ =]' '/some/ {print $3}' /proc/pressure/cpu 2>/dev/null || echo na)"
io_psi_some="$(awk -F'[ =]' '/some/ {print $3}' /proc/pressure/io 2>/dev/null || echo na)"
io_psi_full="$(awk -F'[ =]' '/full/ {print $3}' /proc/pressure/io 2>/dev/null || echo na)"
mem_psi_some="$(awk -F'[ =]' '/some/ {print $3}' /proc/pressure/memory 2>/dev/null || echo na)"

read_cpu() { awk '/^cpu / {print $2,$3,$4,$5,$6,$7,$8}' /proc/stat; }
read u1 n1 s1 i1 w1 irq1 soft1 < <(read_cpu)
sleep 1
read u2 n2 s2 i2 w2 irq2 soft2 < <(read_cpu)
total1=$((u1+n1+s1+i1+w1+irq1+soft1)); total2=$((u2+n2+s2+i2+w2+irq2+soft2)); dt=$((total2-total1)); dw=$((w2-w1)); didle=$((i2-i1))
iowait_pct="0.0"; busy_pct="0.0"
if [ "$dt" -gt 0 ]; then
  iowait_pct="$(awk -v a="$dw" -v b="$dt" 'BEGIN {printf "%.1f", 100*a/b}')"
  busy_pct="$(awk -v idle="$didle" -v total="$dt" 'BEGIN {printf "%.1f", 100*(total-idle)/total}')"
fi

top_cpu="$(ps -eo pid,comm,pcpu,pmem --sort=-pcpu | awk 'NR==2 {printf "%s/%s/%s%%/%s%%", $1,$2,$3,$4}')"
top_mem="$(ps -eo pid,comm,rss,pmem --sort=-rss | awk 'NR==2 {printf "%s/%s/%sKB/%s%%", $1,$2,$3,$4}')"
watch_proc="${SYSTEM_FREEZE_MONITOR_WATCH_REGEX:-}"
watch_line=""
if [ -n "$watch_proc" ]; then
  watch_line="$(pgrep -af "$watch_proc" | head -1 | sed 's/|//g')"
fi

printf '%s|host=%s|load1=%s|busy_pct=%s|iowait_pct=%s|temp=%sC|temp_type=%s|mem_avail_kb=%s|swap_used_kb=%s|psi_cpu_some=%s|psi_io_some=%s|psi_io_full=%s|psi_mem_some=%s|top_cpu=%s|top_mem=%s|watch=%s|uptime=%s\n' \
  "$now" "$host" "$load1" "$busy_pct" "$iowait_pct" "$max_temp_c" "$max_temp_type" "$mem_avail_kb" "$swap_used_kb" \
  "$cpu_psi_some" "$io_psi_some" "$io_psi_full" "$mem_psi_some" "$top_cpu" "$top_mem" "$watch_line" "$uptime_line" >> "$SAMPLE_LOG"

alert=0
reasons=()
if [ "$max_temp_c" != "na" ] && awk -v t="$max_temp_c" 'BEGIN {exit !(t>=90)}'; then alert=1; reasons+=("temp=${max_temp_c}C"); fi
if awk -v v="$iowait_pct" 'BEGIN {exit !(v>=25)}'; then alert=1; reasons+=("iowait=${iowait_pct}%"); fi
if awk -v v="$io_psi_some" 'BEGIN {exit !(v>=20)}'; then alert=1; reasons+=("io_psi_some=${io_psi_some}"); fi
if awk -v v="$load1" 'BEGIN {exit !(v>=8)}'; then alert=1; reasons+=("load1=${load1}"); fi
if [ "$mem_avail_kb" -lt 524288 ]; then alert=1; reasons+=("mem_avail=${mem_avail_kb}KB"); fi

if [ "$alert" -eq 1 ]; then
  printf '%s ALERT %s top_cpu=%s top_mem=%s watch=%s uptime=%s\n' "$now" "${reasons[*]}" "$top_cpu" "$top_mem" "$watch_line" "$uptime_line" >> "$ALERT_LOG"
fi

tail -n 20000 "$SAMPLE_LOG" > "$SAMPLE_LOG.tmp" && mv "$SAMPLE_LOG.tmp" "$SAMPLE_LOG"
tail -n 5000 "$ALERT_LOG" > "$ALERT_LOG.tmp" && mv "$ALERT_LOG.tmp" "$ALERT_LOG"
