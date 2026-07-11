# Virgilio SMTP — Email Delivery for Research Loop

## Credential chain

```
~/.config/himalaya/virgilio-password   -- bash script, reads from:
~/.config/himalaya/virgilio.pass       -- plaintext password (one line, no trailing newline)
```

The `virgilio-password` script strips trailing newlines via `printf '%s' "$pw"`.

## SMTP server details

- **Host**: `smtp.virgilio.it` (alias: `out.virgilio.it`, IP `213.209.1.145`)
- **Port 465**: SMTP_SSL (works with unverified cert)
- **Port 587**: STARTTLS (works with unverified cert)
- **Auth**: PLAIN / LOGIN
- **Certificate**: Hostname mismatch — SSL must use `check_hostname=False` + `verify_mode=CERT_NONE`

## Working send procedure (Python)

```python
import smtplib, ssl, subprocess
from email.mime.text import MIMEText

# Get password
result = subprocess.run(
    ['/home/fausto/.config/himalaya/virgilio-password'],
    capture_output=True, text=True
)
password = result.stdout

# Build message
msg = MIMEText(body, 'plain', 'utf-8')
msg['Subject'] = 'Your Subject'
msg['From'] = 'fausto.lelli@virgilio.it'
msg['To'] = 'fausto.lelli@gmail.com'

# SSL with unverified cert (hostname mismatch)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE

with smtplib.SMTP_SSL('smtp.virgilio.it', 465, context=context, timeout=10) as s:
    s.login('fausto.lelli@virgilio.it', password)
    s.send_message(msg)
```

## Why not himalaya

`himalaya message send` tries to build an IMAP client first (needs IMAP connectivity to send in some configs). With Virgilio's IMAP intermittently failing DNS resolution (`Temporary failure in name resolution`), the SMTP-only Python path is more reliable.

## Cleanup after sending

Remove temp files:
```bash
rm -f /tmp/send_email*.py /tmp/research-loop-report-*.eml
rm -f /tmp/email_body_*.txt
```
