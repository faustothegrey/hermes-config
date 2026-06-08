# Scheduled Restarts

The system is restarted every day at:

- 00:00
- 06:00
- 12:00
- 18:00

Operational implications:

- avoid starting long tasks close to these times;
- checkpoint/save state before the restart windows;
- "nightly tasks" should run only in the 00:30–05:50 local-time window and stop/checkpoint before 05:50.
