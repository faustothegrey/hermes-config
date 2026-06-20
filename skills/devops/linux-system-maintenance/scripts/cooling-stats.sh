#!/bin/bash
# cooling-stats.sh — Capture thermal/system snapshot for cooling period analysis
# Usage: cooling-stats.sh [--pre|--post]
# Writes to ~/.hermes/cooling-stats/YYYY-MM-DD--{pre,post}.log
# Also prints a human-readable snapshot to stdout

set -o pipefail

MODE="${1:-snapshot}"
DATE=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M:%S %Z')
LOGDIR="$HOME/.hermes/cooling-stats"
mkdir -p "$LOGDIR"

if [ "$MODE" = "--pre" ]; then
  SUFFIX="pre"
elif [ "$MODE" = "--post" ]; then
  SUFFIX="post"
else
  SUFFIX="snapshot-$(date '+%H%M%S')"
fi

LOGFILE="$LOGDIR/${DATE}--${SUFFIX}.log"

# ── Collect metrics ──

BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo "unknown")
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
UPTIME_HUMAN=$(uptime -p 2>/dev/null || echo "unknown")
LOAD=$(cat /proc/loadavg 2>/dev/null || echo "? ? ?")

CPU_PKG_TEMP=$(cat /sys/class/hwmon/hwmon4/temp1_input 2>/dev/null | awk '{printf "%.0f", $1/1000}' || echo "?")
CPU_CORE0_TEMP=$(cat /sys/class/hwmon/hwmon4/temp2_input 2>/dev/null | awk '{printf "%.0f", $1/1000}' || echo "?")
CPU_CORE1_TEMP=$(cat /sys/class/hwmon/hwmon4/temp3_input 2>/dev/null | awk '{printf "%.0f", $1/1000}' || echo "?")
CPU_CORE2_TEMP=$(cat /sys/class/hwmon/hwmon4/temp4_input 2>/dev/null | awk '{printf "%.0f", $1/1000}' || echo "?")
CPU_CORE3_TEMP=$(cat /sys/class/hwmon/hwmon4/temp5_input 2>/dev/null | awk '{printf "%.0f", $1/1000}' || echo "?")
ACPI_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.0f", $1/1000}' || echo "?")
FAN_RPM=$(cat /sys/class/hwmon/hwmon3/fan1_input 2>/dev/null || echo "?")

MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
MEM_USED=$(free -h | awk '/^Mem:/{print $3}')
MEM_AVAIL=$(free -h | awk '/^Mem:/{print $7}')
SWAP_TOTAL=$(free -h | awk '/^Swap:/{print $2}')
SWAP_USED=$(free -h | awk '/^Swap:/{print $3}')

DISK_TEMP=$(sudo smartctl -A /dev/sda 2>/dev/null | awk '/Temperature_Celsius/{print $10}' || echo "?")
STAT_CPU=$(grep '^cpu ' /proc/stat 2>/dev/null || echo "?")
STAT_CPUSUM=$(echo "$STAT_CPU" | awk '{for(i=2;i<=NF;i++) s+=$i; print s}')

# ── Write structured log ──

cat > "$LOGFILE" << EOLOG
=== N56VV Cooling Period Stats — $MODE ===
timestamp:      $NOW
boot_id:        $BOOT_ID
uptime_sec:     $UPTIME_SEC
uptime:         $UPTIME_HUMAN
load:           $LOAD
cpu_pkg_temp:   ${CPU_PKG_TEMP}°C
cpu_core0_temp: ${CPU_CORE0_TEMP}°C
cpu_core1_temp: ${CPU_CORE1_TEMP}°C
cpu_core2_temp: ${CPU_CORE2_TEMP}°C
cpu_core3_temp: ${CPU_CORE3_TEMP}°C
acpi_temp:      ${ACPI_TEMP}°C
fan_rpm:        ${FAN_RPM}
mem_total:      $MEM_TOTAL
mem_used:       $MEM_USED
mem_avail:      $MEM_AVAIL
swap_total:     $SWAP_TOTAL
swap_used:      $SWAP_USED
disk_temp:      ${DISK_TEMP}°C
stat_cpu_sum:   $STAT_CPUSUM
EOLOG

# ── Human-readable output ──

echo "═══════════════════════════════════════════"
echo " N56VV Cooling Period Stats — ${SUFFIX^^}"
echo " $NOW"
echo "═══════════════════════════════════════════"
echo ""
echo " Uptime : $UPTIME_HUMAN (boot: $BOOT_ID)"
echo " Load   : $LOAD"
echo ""
echo " ── Temperature ──"
printf " CPU Package : %3s°C\n" "$CPU_PKG_TEMP"
printf "   Core 0    : %3s°C\n" "$CPU_CORE0_TEMP"
printf "   Core 1    : %3s°C\n" "$CPU_CORE1_TEMP"
printf "   Core 2    : %3s°C\n" "$CPU_CORE2_TEMP"
printf "   Core 3    : %3s°C\n" "$CPU_CORE3_TEMP"
printf " ACPI        : %3s°C\n" "$ACPI_TEMP"
printf " HDD         : %3s°C\n" "$DISK_TEMP"
echo ""
echo " ── Fan ──"
printf " CPU Fan     : %4s RPM\n" "$FAN_RPM"
echo ""
echo " ── Memory ──"
printf " RAM         : %s used / %s total (avail: %s)\n" "$MEM_USED" "$MEM_TOTAL" "$MEM_AVAIL"
printf " Swap        : %s used / %s total\n" "$SWAP_USED" "$SWAP_TOTAL"
echo ""
echo " Log salvato: $LOGFILE"
echo "═══════════════════════════════════════════"
