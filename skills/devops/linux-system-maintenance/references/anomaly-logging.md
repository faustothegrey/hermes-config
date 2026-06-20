# Persistent Anomaly Logging — heavy_load_watchdog

When the system's `heavy_load_watchdog.sh` detects a threshold breach (high load, IO
pressure, temperature, memory pressure, low RAM), it now writes structured events to
an anomaly log for persistent recall.

## Log location

```
~/.hermes/anomalies/anomalies.jsonl
```

## Event types

### `start` — written on first detection of a new anomaly

```json
{"event":"start","id":"20260620_181111","ts":"2026-06-20T18:11:11+02:00","host":"fausto-N56VV","reasons":"IO pressure=28.25","critical":0}
```

| Field | Meaning |
|-------|---------|
| `id` | Unique per anomaly burst — `YYYYMMDD_HHMMSS` at first detect |
| `reasons` | Comma-separated list of threshold values that fired |
| `critical` | `1` if any threshold reached critical severity |

### `resolve` — written when all metrics return below threshold

```json
{"event":"resolve","id":"20260620_181111","ts":"2026-06-20T18:17:13+02:00","host":"fausto-N56VV","duration_min":6}
```

`duration_min` = minutes between the `start` and `resolve` timestamps (floor 1).

## State file (tracks ongoing anomaly)

`~/.local/state/system-freeze-monitor/heavy-load-watchdog.state`

```
prev_count=0
last_alert=1781971871
anomaly_start_epoch=0
anomaly_id=
```

- `prev_count` = consecutive checks that found anomalies (reset to 0 when clear)
- `anomaly_start_epoch` = epoch seconds of first detect (used to compute duration)
- `anomaly_id` = unique id for the current anomaly burst

## How to answer "anomalia ancora in corso?"

1. Read the anomaly log: `cat ~/.hermes/anomalies/anomalies.jsonl`
2. Check the state file: look for `prev_count` > 0 = anomaly currently active
3. Check current system metrics for live verification
4. Save notable anomalies to **fact_store** (WARM memory) so recall is instant

## Implementation in heavy_load_watchdog.sh

The logging was injected at three points in the existing script:

### Setup (top of file)
```bash
ANOMALY_LOG="$HOME/.hermes/anomalies/anomalies.jsonl"
mkdir -p "$HOME/.hermes/anomalies"
```

### On first detection (prev_count was 0 → now 1)
When `reasons` is non-empty and `prev_count==0`, generate a unique anomaly ID,
record start epoch, and write a `start` JSON line before updating the state file.

### On resolution (reasons empty, prev_count > 0)
Before resetting the state file to `prev_count=0`, compute
`duration = (now - anomaly_start_epoch) / 60` and write a `resolve` JSON line.

All three state-file writes include the new `anomaly_start_epoch` and `anomaly_id`
fields so they survive across the 5-minute poll interval and any process restarts.

## Thresholds that trigger anomalies

| Metric | Warning (logged) | Critical (no cooldown) |
|--------|------------------|------------------------|
| load5 | ≥ 6.0 | — |
| iowait % | ≥ 20% | ≥ 30% |
| IO pressure (some) | ≥ 20 | — |
| IO pressure (full) | — | ≥ 25 |
| CPU pressure | ≥ 50 | — |
| memory pressure | ≥ 10 | — |
| MemAvailable | < 800 MB | — |
| Temperature | ≥ 95°C | ≥ 95°C |
