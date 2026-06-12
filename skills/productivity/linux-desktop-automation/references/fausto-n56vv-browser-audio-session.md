# fausto-N56VV Chrome secondary display + audio session notes

Concrete working patterns from the session where the user wanted Chrome fullscreen on a secondary display and also tested local speaker/microphone I/O.

## Display geometry observed

`xrandr --query` showed:

- `HDMI-1 connected 1920x1080+0+0` — secondary external display, target for fullscreen Chrome.
- `LVDS-1 connected primary 1920x1080+0+1080` — laptop panel below HDMI.

The Hermes shell was initially `XDG_SESSION_TYPE=tty` without `DISPLAY`, while the graphical user session was X11 on `:0`. Recover GUI access by exporting `DISPLAY=:0` and the active Xorg `-auth` path as `XAUTHORITY`.

## Browser launch lessons

Initial controlled launch with a temporary `--user-data-dir` created a correctly placed fullscreen Chrome window, verified with:

- `xwininfo`: `1920x1080+0+0`
- `xprop`: `_NET_WM_STATE_FULLSCREEN`

But the user reported the page was completely white/blank. Retrying with the normal profile still produced a blank page. The next useful retry was guest mode with a real URL:

```bash
export DISPLAY=:0
google-chrome-stable \
  --guest \
  --new-window https://www.google.com \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --start-fullscreen
```

Guest mode opened as a smaller window despite the flags, so force placement:

```bash
win=$(xwininfo -root -tree | awk '/Google Chrome/ && $0 !~ /google-chrome-stable/ {print $1; exit}')
xdotool windowactivate "$win"
xdotool windowmove "$win" 0 0
xdotool windowsize "$win" 1920 1080
xdotool key F11
xprop -id "$win" _NET_WM_STATE WM_NAME WM_CLASS
xwininfo -id "$win"
```

Final verification showed `Google Chrome` at `1920x1080+0+0` with `_NET_WM_STATE_FULLSCREEN`.

## Navigating after the Chrome profile picker

A later follow-up exposed another important wrinkle: the user still saw the `Who's using Chrome?` profile picker. In that state there is no address bar, so trying to navigate with `Ctrl+L`, typing a URL, and pressing Enter does not work.

What happened:

1. Tab/Enter attempts eventually got past the picker, but landed on an existing profile/page (`Gmail - Google Chrome`) rather than the requested URL.
2. The reliable fix was to ask Chrome itself to open the URL in the already-running browser session:

```bash
export DISPLAY=:0
google-chrome-stable --new-window https://www.google.it
```

Chrome responded with:

```text
Opening in existing browser session.
```

This created a real page window:

```text
Google - Google Chrome
1920x1080+0+0
_NET_WM_STATE_FULLSCREEN
```

If the new URL window is not the focused/fullscreen one, find it by title and re-apply the placement/fullscreen fix:

```bash
export DISPLAY=:0
win=$(xwininfo -root -tree 2>/dev/null | awk '/Google - Google Chrome/ {print $1; exit}')
xdotool windowactivate "$win" || true
xdotool windowmove "$win" 0 0 || true
xdotool windowsize "$win" 1920 1080 || true
state=$(xprop -id "$win" _NET_WM_STATE 2>/dev/null || true)
if ! echo "$state" | grep -q _NET_WM_STATE_FULLSCREEN; then
  xdotool key F11 || true
fi
```

Lesson: for Chrome automation from Hermes, once a Chrome process/session exists, CLI URL opening is often more reliable than synthetic address-bar keystrokes, especially before the profile picker has been dismissed.

## Audio notes from same desktop session

Speaker output initially failed because the default sink was muted and at 0% volume. Fix:

```bash
pactl set-sink-mute @DEFAULT_SINK@ 0
pactl set-sink-volume @DEFAULT_SINK@ 60%
```

The user preferred Hermes/Edge TTS over `spd-say`, which sounded mechanical.

External USB microphone was detected as the default source:

`alsa_input.usb-C-Media_Electronics_Inc._USB_PnP_Sound_Device-00.mono-fallback`

A short `parecord` capture had strong RMS/peak levels, confirming the microphone was actually receiving the user's voice.
