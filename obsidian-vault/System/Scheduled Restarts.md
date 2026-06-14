# Scheduled Restarts

Status updated 2026-06-14: the fixed daily scheduled restarts are disabled.

Previous daily restart times were:

- 00:00
- 06:00
- 12:00
- 18:00

Current policy:

- Do not rely on preventive scheduled restarts while the system remains stable.
- Keep background health monitoring active.
- If a genuinely dangerous thermal condition is detected, send alerts via Telegram and email, then perform a complete poweroff.
- If unexpected freezes return, bring back scheduled restarts.

Operational implications:

- Long tasks no longer need to avoid the old daily restart windows by default.
- Still checkpoint important long-running work because emergency poweroff can happen if the thermal safety threshold is sustained.

Verification 2026-06-14 19:42 CEST:

- Root crontab checked: no fixed restart entries remain.
- `temp-reboot-monitor.service` checked active as `Temperature safety poweroff monitor`.
- Telegram + Virgilio email alert test was confirmed successful by the user.
- Detailed live-state snapshot and exact safety configuration are in [[System/fausto-N56VV Stability Monitoring]].
