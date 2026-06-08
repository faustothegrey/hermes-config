# Telegram + systemd setup pattern

This reference captures a concrete Hermes Gateway setup pattern that is likely to recur.

## Situation

- `hermes` worked for the normal user but was not in root/systemd PATH.
- The installed wrapper was at `~/.local/bin/hermes` and executed the venv-backed Hermes binary under `~/.hermes/hermes-agent/venv/bin/hermes`.
- A user systemd service was appropriate for the gateway.
- In the agent shell, `systemctl --user` initially failed because the user bus variables were missing, but `/run/user/<uid>` existed.
- Telegram token was already configured and valid, but the gateway logged that no user allowlists were configured, so all Telegram users were denied.

## Useful probes

```bash
command -v hermes || true
readlink -f ~/.local/bin/hermes
head -n 5 ~/.local/bin/hermes
hermes status --all
loginctl show-user "$USER" -p Linger
XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user status hermes-gateway.service --no-pager
```

## User systemd recovery pattern

If `systemctl --user` reports missing `DBUS_SESSION_BUS_ADDRESS` / `XDG_RUNTIME_DIR`, try:

```bash
XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user daemon-reload
XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user enable hermes-gateway.service
XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user restart hermes-gateway.service
```

For persistence after logout/reboot:

```bash
sudo loginctl enable-linger "$USER"
```

## Telegram finalization pattern

A valid `TELEGRAM_BOT_TOKEN` does not imply the integration is usable. Check these in `~/.hermes/.env`:

```dotenv
TELEGRAM_ALLOWED_USERS=<numeric-user-id>
TELEGRAM_HOME_CHANNEL=<numeric-user-id-or-chat-id>
```

To find a Telegram DM user ID, tell the user to message `@userinfobot` and copy the numeric `Id`. If `getUpdates` contains recent messages to the bot, those `from.id` values can also identify candidate users, but do not guess if none are present.

After editing `.env`:

```bash
XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user restart hermes-gateway.service
hermes status --all
journalctl --user -u hermes-gateway.service --since '5 minutes ago' --no-pager
```

## Security note

Do not print Telegram bot tokens. When validating through `getMe`, report only `ok`, bot username, and bot id. Avoid `GATEWAY_ALLOW_ALL_USERS=true` unless the user explicitly asks for temporary open testing.
