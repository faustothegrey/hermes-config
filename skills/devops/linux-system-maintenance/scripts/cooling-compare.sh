#!/bin/bash
# cooling-compare.sh — Compare pre and post cooling period stats
# Reads today's --pre and --post log files and produces a formatted comparison.

LOGDIR="$HOME/.hermes/cooling-stats"
DATE=$(date '+%Y-%m-%d')
PRE_LOG="$LOGDIR/${DATE}--pre.log"
POST_LOG="$LOGDIR/${DATE}--post.log"

if [ ! -f "$PRE_LOG" ]; then
  YESTERDAY=$(date -d 'yesterday' '+%Y-%m-%d')
  PRE_LOG="$LOGDIR/${YESTERDAY}--pre.log"
fi

if [ ! -f "$PRE_LOG" ]; then
  echo "❌ No pre-cooling log found for $DATE or yesterday. Cooling period did not run?"
  exit 0
fi

if [ ! -f "$POST_LOG" ]; then
  echo "❌ Post log not yet available. Running snapshot..."
  $HOME/.hermes/scripts/cooling-stats.sh --post
  POST_LOG="$LOGDIR/${DATE}--post.log"
fi

get_field() { grep "^${2}:" "$1" 2>/dev/null | head -1 | awk -F': ' '{print $2}'; }
get_temp() { local v; v=$(get_field "$1" "$2"); echo "$v" | sed 's/°C//'; }

echo "═══════════════════════════════════════════════════════════"
echo "  N56VV Nightly Cooling Period — Report $(date '+%Y-%m-%d')"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo " Pre-cooling : $(get_field "$PRE_LOG" "timestamp")"
echo " Post-cooling: $(get_field "$POST_LOG" "timestamp")"
echo ""

echo " ┌────────────────────┬─────────┬──────────┬────────┐"
echo " │ Metric             │ Pre     │ Post     │ Delta  │"
echo " ├────────────────────┼─────────┬──────────┬────────┤"

compare_temp() {
  local label="$1" pre_field="$2" post_field="$3"
  local pre_val=$(get_temp "$PRE_LOG" "$pre_field")
  local post_val=$(get_temp "$POST_LOG" "$post_field")
  if [ "$pre_val" = "?" ] || [ "$post_val" = "?" ]; then
    printf " │ %-18s │ %5s   │ %5s   │  n/a   │\n" "$label" "$pre_val" "$post_val"
    return
  fi
  local delta=$(( pre_val - post_val ))
  local arrow
  if [ "$delta" -gt 0 ]; then arrow="↓${delta}°C ✓"
  elif [ "$delta" -lt 0 ]; then arrow="↑$(( -delta ))°C ⚠"
  else arrow="  0°C —"
  fi
  printf " │ %-18s │ %5s°C  │ %5s°C  │ %s │\n" "$label" "$pre_val" "$post_val" "$arrow"
}

compare_temp "CPU Package" "cpu_pkg_temp" "cpu_pkg_temp"
compare_temp "Core 0" "cpu_core0_temp" "cpu_core0_temp"
compare_temp "Core 1" "cpu_core1_temp" "cpu_core1_temp"
compare_temp "Core 2" "cpu_core2_temp" "cpu_core2_temp"
compare_temp "Core 3" "cpu_core3_temp" "cpu_core3_temp"
compare_temp "ACPI" "acpi_temp" "acpi_temp"
compare_temp "HDD" "disk_temp" "disk_temp"

echo " └────────────────────┴─────────┴──────────┴────────┘"
echo ""
echo " ── Fan ──"
echo "  Pre: $(get_field "$PRE_LOG" "fan_rpm") RPM  |  Post: $(get_field "$POST_LOG" "fan_rpm") RPM"
echo ""
echo " ── System Load ──"
echo "  Pre:  load: $(get_field "$PRE_LOG" "load")"
echo "  Post: load: $(get_field "$POST_LOG" "load")"
echo ""
echo " ── Uptime ──"
echo "  Pre:  $(get_field "$PRE_LOG" "uptime")"
echo "  Post: $(get_field "$POST_LOG" "uptime")"

PRE_BOOT=$(get_field "$PRE_LOG" "boot_id")
POST_BOOT=$(get_field "$POST_LOG" "boot_id")
echo ""
if [ "$PRE_BOOT" != "$POST_BOOT" ]; then
  echo " ✓ Reboot confirmed: boot_id changed (cooling period successful)"
else
  echo " ⚠ Same boot_id — system did NOT reboot!"
fi
echo ""
echo " Logs: $LOGDIR/${DATE}--{pre,post}.log"
echo "═══════════════════════════════════════════════════════════"
