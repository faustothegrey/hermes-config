# fausto-N56VV: disable fixed restarts, keep safety poweroff

Session pattern: user judged the machine stable enough to remove fixed preventive restarts and rely on lightweight monitoring plus emergency thermal poweroff.

## Durable policy

- Fixed daily root-cron restarts at 00:00, 06:00, 12:00, and 18:00 are disabled unless unexpected freezes return.
- Keep lightweight monitors active:
  - Hermes cron `heavy-load-watchdog` every 5 minutes, Telegram-only alerting, no agent.
  - User `system-freeze-monitor.timer` for minute-level evidence sampling.
  - Root `temp-reboot-monitor.service` for sustained thermal safety action.
- Dangerous thermal condition policy:
  - Monitor CPU-like zones (`x86_pkg_temp`, `acpitz`).
  - Threshold: `>=95°C` for 30 consecutive 10-second checks (~5 minutes).
  - Send alert through Telegram and email, then schedule complete poweroff after a short delay.
  - Use a marker file such as `/run/temp-reboot-monitor.scheduled` to dedupe actions.

## Verification sequence

1. Verify current health before changing policy:
   - uptime/load, memory/swap, disk, PSI, thermal zones, failed system/user units.
2. Verify fixed restarts source before editing:
   - root crontab was the source in this session (`sudo -n crontab -l`).
   - Remove only the fixed power-action lines; preserve comments/other jobs.
3. Update the root thermal monitor and config, then restart service:
   - install script/config with root permissions;
   - `systemctl daemon-reload` if the unit changes;
   - restart and check `systemctl status temp-reboot-monitor.service`.
4. Test delivery without scheduling shutdown:
   - Send a clearly marked `TEST ONLY` Telegram message.
   - Send a clearly marked `TEST ONLY` email.
   - Verify the safety marker does not exist after the test.
5. Update Obsidian operational notes and compact Hermes memory.

## Email alert implementation lesson

Himalaya was configured for Virgilio, but `himalaya template send` failed to parse simple generated templates and `himalaya message send` hit a `mail-parser` panic. Do not encode this as “Himalaya is broken”; the durable fix for watchdog scripts is to use Python stdlib SMTP directly with the same Virgilio credentials:

- SMTP host: `smtp.virgilio.it`
- port: `465` over SSL
- login/from: `fausto.lelli@virgilio.it`
- password command: `/home/fausto/.config/himalaya/virgilio-password`
- recipient: `fausto.lelli@gmail.com`

This is appropriate for deterministic root/user watchdog scripts because it avoids CLI template parsing and gives explicit success/failure.

## Safety notes

- Do not trigger the real poweroff branch while testing. Test notifications independently and verify no marker/action was scheduled.
- Prefer delayed poweroff (`systemd-run --on-active=2min ... poweroff`) over immediate action so alerts have time to leave and the scheduled action is observable/cancelable.
- Avoid poweroff on load/IO pressure alone unless the user explicitly defines conservative thresholds; thermal sustained danger is the safer automatic-action trigger.
- Keep full thresholds, commands, test results, and live snapshots in the Obsidian vault; keep persistent memory compact with links to vault notes.
