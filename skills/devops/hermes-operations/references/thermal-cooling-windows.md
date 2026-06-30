# Thermal Cooling Windows — fausto-N56VV

## Heat wave thermal model

The N56VV idles at ~81°C and freezes above 95°C even with moderate load. Ambient heat wave temperatures compound this — the machine needs aggressive passive cooling (rtcwake shutdown) during the hottest hours rather than just fan-based active cooling.

### Peak temperature curve (Mediterranean summer)

| Time | Solar | Ambient | Machine risk |
|------|-------|---------|-------------|
| 08-11 | Rising | Warming up | Low — morning air still cool |
| 11-12 | High | Getting hot | Moderate — start shutdown |
| 12-15 | Peak | Rapidly rising | **HIGH — peak insolation** |
| 15-17 | Declining | **Peak ambient temp** (2h solar lag) | **HIGH — hottest ambient** |
| 17-19 | Low | Still very warm (ground radiates) | Moderate — slow evening cooldown |
| 19+ | None | Gradual cooling | Safe — work can resume |

### Key insight: the 2-hour thermal lag

The hottest ambient temperature arrives ~2 hours AFTER solar peak (15:00-17:00 vs 12:00-15:00 sun). A cooling window that ends at 16:00 (the old window) misses the peak ambient hour entirely. The window should extend to at least 19:00 during heat waves to cover:

- Peak solar radiation (12-15)
- Peak ambient temperature (15-17)
- Evening heat-soak from ground thermal mass (17-19)

### Night bleed window

After 7+ hours of evening compute, the CPU die is heat-soaked — internal temperature stays elevated even after ambient drops. A 1h night shutdown at 02:00-03:00 lets the thermal mass dissipate before the 8h morning shift (03:00-11:00) begins.

## Heat-wave vs normal mode

| Parameter | Normal | Heat wave |
|-----------|--------|-----------|
| Diurnal cooling | 12-16 (4h) | 11-19 (8h) |
| Night cooling | 02-04 (2h) | 02-03 (1h) |
| Morning work | 04-12 (8h) | 03-11 (8h) |
| Evening work | 16-02 (10h) | 19-02 (7h) |

Return to normal mode when ambient temps drop below 30°C sustained.

## Script mechanism

Each cooling window is implemented by a `no_agent=true` cron job running `sudo rtcwake -m off -s <seconds>`. The cron fires at window start, captures thermal stats, then immediately shuts down with a hardware RTC wake timer.

Key file: `~/.hermes/scripts/cooling-period.sh` (night) and `cooling-period-diurno.sh` (day).

Migration steps (for changing window size):
1. Update `-s <seconds>` in the script
2. Update cron schedule if start time changes
3. Update post-report cron schedule to fire at new end time + 10min
4. Update thermal snapshot cron `daytime-thermal-snapshot` to only run during work hours
5. Update memory + user profile
6. Verify with `cronjob action='list'`
