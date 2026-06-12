---
name: linux-desktop-automation
description: "Control and verify local Linux desktop UI tasks from Hermes: audio I/O, X11 displays, browser windows, fullscreen placement, and basic GUI automation."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [linux, desktop, x11, audio, chrome, displays, gui-automation]
---

# Linux Desktop Automation

Use this class-level skill when the user asks Hermes to interact with the local Linux desktop: play audio through speakers, test microphones, inspect monitor layout, launch GUI apps, place browser windows, or verify fullscreen/window state.

## Core workflow

1. Establish the session/display context before acting.
   - Check whether the agent shell already has `DISPLAY`, `WAYLAND_DISPLAY`, `XDG_SESSION_TYPE`, and `XAUTHORITY`.
   - If running from SSH/TTY but the user has a graphical login, inspect `loginctl`, `who`, and `systemctl --user show-environment` for `DISPLAY`, `XAUTHORITY`, and `DBUS_SESSION_BUS_ADDRESS`.
   - For X11 sessions, `DISPLAY=:0` plus the Xorg `-auth` path is often enough for GUI commands.
2. Discover the target device/layout instead of guessing.
   - Displays: `xrandr --query` and read connected outputs, resolutions, and offsets.
   - Audio output: `pactl list short sinks`, default sink, mute state, and volume.
   - Audio input: `pactl list short sources`, default source, `arecord -l`, and USB device identity when relevant.
3. Execute the GUI/audio action using the concrete coordinates or device name.
4. Verify with the desktop system itself.
   - For windows: `xwininfo`, `xprop`, or `wmctrl -lG` when available.
   - For audio: replay a real sound/TTS sample or record and compute signal levels.
5. Report the actual verified state: device/output name, coordinates, size, fullscreen state, mute/volume, or capture levels.

## Chrome fullscreen on a secondary X11 monitor

When the user specifically asks for Chrome fullscreen on a secondary display, do not merely launch Chrome and hope the window manager places it correctly.

1. Read monitor geometry with `xrandr --query`. Example interpretation:
   - `HDMI-1 connected 1920x1080+0+0` means the HDMI display occupies X=0, Y=0, width=1920, height=1080.
   - `LVDS-1 connected primary 1920x1080+0+1080` means the laptop panel is below it and is primary.
2. Launch Chrome with explicit placement and size for the target monitor:
   ```bash
   export DISPLAY=:0
   export XAUTHORITY=$(ps -C Xorg -o args= | sed -n 's/.* -auth \([^ ]*\).*/\1/p' | head -n 1)
   google-chrome-stable \
     --user-data-dir=/tmp/hermes-chrome-secondary \
     --no-first-run \
     --new-window about:blank \
     --window-position=<x>,<y> \
     --window-size=<width>,<height> \
     --start-fullscreen
   ```
3. Prefer a dedicated temporary `--user-data-dir` only for controlled test windows where a blank first-run page is acceptable. If the user reports a completely white/blank page or Chrome setup/update checks interfere, retry with the normal profile or with `--guest` rather than persisting the temporary profile. For visual confirmation, open a real URL such as `https://www.google.com` instead of `about:blank`, because `about:blank` can look like a failed render.
4. Guest-mode retry pattern:
   ```bash
   google-chrome-stable \
     --guest \
     --new-window https://www.google.com \
     --window-position=<x>,<y> \
     --window-size=<width>,<height> \
     --start-fullscreen
   ```
   Some window managers ignore these placement flags in guest mode; find the actual window and force placement with `xdotool windowactivate`, `xdotool windowmove`, `xdotool windowsize`, then send `F11`.
5. If Chrome shows a transient popup (for example an update warning), dismiss it with a minimal window-manager/key action and then re-check the real browser window.
6. If Chrome is stuck on the profile picker / “Who’s using Chrome?” screen, `Ctrl+L` will not work because there is no address bar yet. First pass the picker (Tab/Enter can work, but may land on an unintended profile). More reliably, once a browser session exists, open the desired URL from the CLI with `google-chrome-stable --new-window https://…`; Chrome will print “Opening in existing browser session” and create/navigate a real browser window. Then re-activate the new URL window and re-apply placement/fullscreen verification.
7. Verify the window is on the requested monitor and fullscreen:
   ```bash
   xwininfo -root -tree | grep -i 'Google Chrome'
   xprop -id <window-id> _NET_WM_STATE WM_NAME WM_CLASS
   xwininfo -id <window-id>
   ```
   The desired evidence is geometry matching the target output and `_NET_WM_STATE_FULLSCREEN`, e.g. `1920x1080+0+0` on `HDMI-1`.

Worked examples:
- `references/chrome-secondary-x11-example.md` for a successful HDMI secondary-display launch and verification transcript.
- `references/fausto-n56vv-browser-audio-session.md` for the follow-up where a blank Chrome page required normal/guest-profile retries plus forced placement.

## Audio I/O checks

- If the user hears nothing, check default sink mute/volume first; the simple failure mode may be `Mute: yes` and `Volume: 0%`.
- Prefer Hermes `text_to_speech` output for a natural voice test. System voices such as `spd-say` can be noticeably mechanical.
- For a microphone test, record a short sample from the default source with `parecord`/`timeout`, then compute RMS/peak to confirm real input rather than relying only on device enumeration.

## Pitfalls

- A shell launched from SSH or TTY may not inherit `DISPLAY`/`XAUTHORITY`, even while the user is logged into GNOME/X11 locally. Recover the graphical environment before using `xrandr`, `xwininfo`, or GUI apps.
- Do not use shell-level `nohup ... &` for long-lived GUI launches under Hermes terminal tools; use a tracked background process when necessary, then verify in a separate command.
- Monitor names and offsets are environment-specific. Never hardcode `HDMI-1` or `+0+0` without checking `xrandr` in the current session.
- `--start-fullscreen` alone is not sufficient evidence. Always verify geometry and `_NET_WM_STATE_FULLSCREEN` after launch.
- If the browser window is white/blank, treat it as a profile/startup/content issue before assuming monitor placement failed. Retry with a normal profile or `--guest`, and use a non-blank URL for visual confirmation.

## Verification checklist

For display/browser tasks, final answer should include:

- Target output name and geometry from `xrandr`.
- Browser/window title or ID.
- Window position and size from `xwininfo`/`wmctrl`.
- Fullscreen state from `xprop` when available.

For audio tasks, final answer should include:

- Sink/source device used.
- Mute/volume or capture level.
- Whether an actual playback/capture test succeeded.
