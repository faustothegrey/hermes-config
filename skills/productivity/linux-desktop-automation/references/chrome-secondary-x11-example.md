# Chrome fullscreen on secondary X11 display — worked example

This is a condensed example of the successful pattern for launching Chrome fullscreen on a secondary monitor from a Hermes CLI/SSH-like shell.

## Observed layout

`xrandr --query` reported:

```text
Screen 0: current 1920 x 2160
LVDS-1 connected primary 1920x1080+0+1080
HDMI-1 connected 1920x1080+0+0
```

Interpretation: HDMI-1 is the secondary display at the top of the combined desktop, with geometry `1920x1080+0+0`; the laptop panel is below it.

## Launch pattern

Use the graphical X11 environment rather than the SSH/TTY shell environment:

```bash
export DISPLAY=:0
export XAUTHORITY=$(ps -C Xorg -o args= | sed -n 's/.* -auth \([^ ]*\).*/\1/p' | head -n 1)
mkdir -p /tmp/hermes-chrome-secondary

google-chrome-stable \
  --user-data-dir=/tmp/hermes-chrome-secondary \
  --no-first-run \
  --new-window about:blank \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --start-fullscreen
```

In Hermes, run long-lived GUI apps as a tracked background process, then verify separately.

## Verification evidence

`xwininfo -root -tree` found:

```text
"about:blank - Google Chrome" 1920x1080+0+0 +0+0
```

`xprop -id <window-id> _NET_WM_STATE` included:

```text
_NET_WM_STATE_FULLSCREEN
```

`xwininfo -id <window-id>` confirmed:

```text
Absolute upper-left X: 0
Absolute upper-left Y: 0
Width: 1920
Height: 1080
```

## Practical notes

- If Chrome opens a small transient popup such as `Can't update Chrome`, dismiss it and verify again.
- Geometry and monitor names are host-specific; always recompute from `xrandr`.
- Verification should mention both geometry and fullscreen state, not just that Chrome started.
