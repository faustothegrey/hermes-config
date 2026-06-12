# Virgilio Mail with Himalaya

Known-good setup verified against a `@virgilio.it` mailbox using Himalaya v1.2.0.

## Minimal config

```toml
[accounts.virgilio]
email = "user@virgilio.it"
display-name = "User Name"
default = true

backend.type = "imap"
backend.host = "imap.virgilio.it"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "user@virgilio.it"
backend.auth.type = "password"
backend.auth.cmd = "/home/USER/.config/himalaya/virgilio-password"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.virgilio.it"
message.send.backend.port = 465
message.send.backend.encryption.type = "tls"
message.send.backend.login = "user@virgilio.it"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "/home/USER/.config/himalaya/virgilio-password"

folder.aliases.inbox = "INBOX"
folder.aliases.sent = "Posta Inviata"
folder.aliases.drafts = "Bozze"
folder.aliases.trash = "Cestino"
```

## Password file helper

If the user wants to write the password into a local file rather than paste it into chat, keep it outside `config.toml` and use `auth.cmd`.

```sh
#!/usr/bin/env sh
set -eu
pw_file="/home/USER/.config/himalaya/virgilio.pass"
if [ ! -r "$pw_file" ]; then
  echo "Password file not found: $pw_file" >&2
  exit 1
fi
IFS= read -r pw < "$pw_file" || true
printf '%s' "$pw"
```

Permissions:

```bash
chmod 700 ~/.config/himalaya
chmod 600 ~/.config/himalaya/config.toml ~/.config/himalaya/virgilio.pass
chmod 700 ~/.config/himalaya/virgilio-password
```

If the password file was edited manually, normalize it without printing secrets:

```bash
python3 - <<'PY'
from pathlib import Path
import os
p = Path.home() / '.config/himalaya/virgilio.pass'
lines = p.read_text().splitlines()
p.write_text((lines[0] if lines else '') + '\n')
os.chmod(p, 0o600)
PY
```

## Verification workflow

Use `-a ACCOUNT` on subcommands (not as a global flag):

```bash
himalaya folder list -a virgilio --output json
himalaya envelope list -a virgilio --page-size 5 --output json
himalaya account doctor virgilio --output json
```

Expected folder names observed for Virgilio:

- `INBOX`
- `Posta Inviata`
- `Bozze`
- `Cestino`
- `Spam`
- `Archivio` and year subfolders

`account doctor` reports both IMAP and SMTP integrity; it is useful before sending a real email.

## Sending test email

Prefer `template send` from stdin:

```bash
cat <<'EOF' | himalaya template send -a virgilio --output plain
From: User Name <user@virgilio.it>
To: recipient@example.com
Subject: ciao da Hermes

ciao da Hermes
EOF
```

Then verify Sent:

```bash
himalaya envelope list -a virgilio --folder 'Posta Inviata' --page-size 3 --output json
```

## Pitfalls

- `himalaya --account virgilio ...` is not valid in v1.2.0; account selection is a subcommand option such as `himalaya folder list -a virgilio`.
- If IMAP returns `AUTHENTICATIONFAILED`, first check the password file content/format and whether the user wrote the correct password. The server connection can still be correct.
- Passing a whole raw message as a shell argument to `himalaya message send` caused a panic in `mail-parser-0.9.4` on v1.2.0. Piping to `himalaya template send` succeeded.
- Do not print the password while checking file formatting; inspect byte counts, newline/CR presence, and line count only.
