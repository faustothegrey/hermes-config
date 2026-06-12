---
tags:
  - hermes
  - chrome
  - display
  - x11
  - fausto-N56VV
created: 2026-06-12 19:22:17 CEST
updated: 2026-06-12 19:22:17 CEST
---

# Chrome fullscreen on secondary display

This note records the working procedure discovered on 2026-06-12 for launching Google Chrome fullscreen on the secondary display of fausto-N56VV.

## Hardware/display layout

Host/session:

- Host: fausto-N56VV
- Graphical session: X11
- Usable display from terminal/SSH/Hermes tools: `DISPLAY=:0`
- `XDG_SESSION_TYPE` from graphical user environment: `x11`
- X server auth can be inferred from the running Xorg command if needed:
  - `ps -C Xorg -o args= | sed -n 's/.* -auth \([^ ]*\).*/\1/p' | head -n 1`

`xrandr --query` showed:

```text
Screen 0: minimum 320 x 200, current 1920 x 2160, maximum 16384 x 16384
LVDS-1 connected primary 1920x1080+0+1080
HDMI-1 connected 1920x1080+0+0
```

Important coordinate mapping:

- `HDMI-1` is the secondary display.
- `HDMI-1` is located at `+0+0`.
- `HDMI-1` resolution is `1920x1080`.
- `LVDS-1` is the laptop/internal primary display.
- `LVDS-1` is located below HDMI at `+0+1080`.
- Combined virtual desktop size is `1920x2160`.

Therefore, to place a browser fullscreen on the secondary display, target:

```text
x=0
y=0
width=1920
height=1080
```

## Packages/tools used

Chrome was available:

```text
/usr/bin/google-chrome
/usr/bin/google-chrome-stable
```

Initially missing, then installed successfully via apt:

```text
/usr/bin/xdotool
/usr/bin/wmctrl
```

Useful inspection tools already available:

```text
xrandr
xwininfo
xprop
```

## What did not work well

### Temporary profile launch

Initial attempt used an isolated profile:

```bash
google-chrome-stable \
  --user-data-dir=/tmp/hermes-chrome-secondary \
  --no-first-run \
  --new-window about:blank \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --start-fullscreen
```

This created a correct fullscreen window on HDMI-1, but the user saw a blank/white page. It also triggered a `Can't update Chrome` popup.

Verified state from X11 was correct despite the visual blank page:

```text
Window: about:blank - Google Chrome
Position: +0+0
Size: 1920x1080
State: _NET_WM_STATE_FULLSCREEN
```

### Normal profile launch

Launching with the normal profile and `about:blank` also produced a blank page for the user:

```bash
google-chrome-stable \
  --new-window about:blank \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --start-fullscreen
```

It did create the correct fullscreen X11 window:

```text
Window: about:blank - Google Chrome
Position: +0+0
Size: 1920x1080
State: _NET_WM_STATE_FULLSCREEN
Display: HDMI-1
```

But visually it still appeared blank.

## Working solution: Guest profile + force placement/fullscreen

The successful approach was:

1. Close existing Chrome processes.
2. Start Chrome with `--guest`.
3. Use a real URL instead of `about:blank`.
4. If it opens as a normal window, force it to HDMI-1 with `xdotool`, resize to `1920x1080`, then press F11.

Launch command:

```bash
export DISPLAY=:0

google-chrome-stable \
  --guest \
  --new-window https://www.google.com \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --start-fullscreen
```

In practice, the Guest window first opened as a smaller window:

```text
Window: Google Chrome
Size: 1024x758
Position: +448+198
```

Then it was fixed manually with `xdotool`:

```bash
export DISPLAY=:0

win=$(xwininfo -root -tree 2>/dev/null | awk '/Google Chrome/ && $0 !~ /google-chrome-stable/ {print $1; exit}')
xdotool windowactivate "$win"
sleep 0.2
xdotool windowmove "$win" 0 0
xdotool windowsize "$win" 1920 1080
sleep 0.2
xdotool key F11
```

Final verified state:

```text
Window: Google Chrome
Coordinates: +0+0
Size: 1920x1080
State: _NET_WM_STATE_FULLSCREEN
Display: HDMI-1 / secondary display
```

`xprop` showed:

```text
_NET_WM_STATE(ATOM) = _NET_WM_STATE_FULLSCREEN, _NET_WM_STATE_FOCUSED
WM_NAME(UTF8_STRING) = "Google Chrome"
```

`xwininfo` showed:

```text
Absolute upper-left X: 0
Absolute upper-left Y: 0
Width: 1920
Height: 1080
Corners: +0+0 -0+0 -0-1080 +0-1080
```

The user confirmed this worked.

## Recommended repeat command

Use this when asked to open Chrome fullscreen on the secondary display:

```bash
export DISPLAY=:0

# Optional: close existing Chrome first. Be careful: this closes user Chrome sessions.
pkill -TERM -f '[g]oogle-chrome|[c]hrome' 2>/dev/null || true
sleep 2

# Start Guest Chrome on the secondary display.
google-chrome-stable \
  --guest \
  --new-window https://www.google.com \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --start-fullscreen &

sleep 3

# Dismiss possible Chrome update popup.
xdotool key Escape 2>/dev/null || true
sleep 1

# Force the visible Chrome window to HDMI-1 and fullscreen.
win=$(xwininfo -root -tree 2>/dev/null | awk '/Google Chrome/ && $0 !~ /google-chrome-stable/ {print $1; exit}')
if [ -n "$win" ]; then
  xdotool windowactivate "$win" || true
  sleep 0.2
  xdotool windowmove "$win" 0 0 || true
  xdotool windowsize "$win" 1920 1080 || true
  sleep 0.2
  xdotool key F11 || true
fi
```

Note for Hermes tool usage: do not use shell `&` in foreground `terminal()` calls. If launching Chrome from Hermes, use `terminal(background=true)` for the long-lived Chrome process, then run the xdotool verification/fix commands in separate foreground tool calls.

## Verification commands

Check display layout:

```bash
export DISPLAY=:0
xrandr --query | grep ' connected'
```

Expected:

```text
LVDS-1 connected primary 1920x1080+0+1080
HDMI-1 connected 1920x1080+0+0
```

Check Chrome window geometry/fullscreen:

```bash
export DISPLAY=:0
win=$(xwininfo -root -tree 2>/dev/null | awk '/Google Chrome/ && $0 !~ /google-chrome-stable/ {print $1; exit}')
echo "$win"
xprop -id "$win" _NET_WM_STATE WM_NAME WM_CLASS 2>/dev/null || true
xwininfo -id "$win" | sed -n '1,24p'
```

Expected final result:

```text
_NET_WM_STATE includes _NET_WM_STATE_FULLSCREEN
Absolute upper-left X: 0
Absolute upper-left Y: 0
Width: 1920
Height: 1080
```

## Related observations from same session

Audio/speaker:

- Default output sink was initially muted and at 0%.
- Fixed with:

```bash
pactl set-sink-mute @DEFAULT_SINK@ 0
pactl set-sink-volume @DEFAULT_SINK@ 60%
```

- Default output sink:

```text
alsa_output.pci-0000_00_1b.0.analog-stereo
```

- User preferred the more natural Hermes/Edge TTS voice over `spd-say`, which sounded mechanical.

Microphone:

- External USB mic/audio device is present and default input:

```text
USB PnP Sound Device
C-Media Electronics Inc.
alsa_input.usb-C-Media_Electronics_Inc._USB_PnP_Sound_Device-00.mono-fallback
```

- `arecord -l` showed:

```text
card 1: Device [USB PnP Sound Device], device 0: USB Audio [USB Audio]
```

- Test recording detected voice clearly:

```text
Duration: 3.91s
RMS: 17274
Peak: 31953
Result: voice/audio detected
```
