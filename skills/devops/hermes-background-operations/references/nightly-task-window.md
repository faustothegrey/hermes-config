# Nightly task window

Use this when the user asks for a "nightly task" or overnight execution.

## Definition

For this user, a nightly task is work that may run only during the local-time window:

- Earliest start: 00:30
- Latest stop: 05:50

This deliberately avoids the daily restart at 00:00 and leaves a 10-minute buffer before the 06:00 restart.

## Cron start pattern

A typical nightly start schedule is:

```cron
30 0 * * *
```

Cron only controls start time. The task itself still needs a hard-stop/checkpoint rule.

## Prompt clause for LLM-driven jobs

Add this clause to nightly cron prompts:

```text
This is a nightly task. Work only during the local-time window 00:30–05:50. Do not start before 00:30. If the task is not complete by 05:50, stop immediately, save/checkpoint all useful state, summarize what was completed and what remains, and do not continue beyond 05:50. Prefer small resumable units of work.
```

## Script guard pattern

For worker scripts, check the local wall clock before each unit of work:

```python
from datetime import datetime, time

STOP = time(5, 50)
START = time(0, 30)

def in_nightly_window(now=None):
    now = now or datetime.now().time()
    return START <= now < STOP

def should_stop_for_nightly(now=None):
    now = now or datetime.now().time()
    return now >= STOP or now < START

for item in work_items:
    if should_stop_for_nightly():
        save_checkpoint()
        print("Nightly window ended; checkpoint saved. Remaining work will resume next nightly window.")
        break
    process_one_item(item)
    save_checkpoint()
```

## Operational notes

- Do not schedule long tasks at 05:00+ unless they are guaranteed to checkpoint before 05:50.
- Prefer resumable chunking over a single monolithic run.
- If the user asks for a long task outside the nightly window and calls it a nightly task, schedule/defer it rather than starting immediately.
- If a result report is useful, deliver it after checkpoint/stop; otherwise stay quiet for script-only watchdog style jobs.
