#!/usr/bin/env python3
"""
send-recap-email.py — Send a recap email via SMTP_SSL with fallback.

Usage:
  ./send-recap-email.py <eml_file> <subject> <to_addr>

Reads the email body from <eml_file> (raw RFC 2822 format), constructs
a MIME message with the given Subject and To, and sends via SMTP_SSL
on port 465 using Virgilio SMTP credentials.

Dependencies: Python stdlib only (smtplib, ssl, email).

Environment / config:
  - Password file: ~/.config/himalaya/virgilio.pass (first line = password)
  - Sender: fausto.lelli@virgilio.it
  - SMTP host: smtp.virgilio.it:465 (SSL)

Exit codes:
  0 — sent successfully
  1 — missing file / arguments
  2 — auth/SMTP failure
"""

import smtplib
import ssl
import sys
from email.mime.text import MIMEText
from pathlib import Path


def main():
    if len(sys.argv) < 4:
        print("Usage: send-recap-email.py <eml_file> <subject> <to_addr>", file=sys.stderr)
        sys.exit(1)

    eml_file = sys.argv[1]
    subject = sys.argv[2]
    to_addr = sys.argv[3]
    from_addr = "fausto.lelli@virgilio.it"

    # Read email body file
    eml_path = Path(eml_file)
    if not eml_path.exists():
        print(f"Error: file not found: {eml_file}", file=sys.stderr)
        sys.exit(1)

    body = eml_path.read_text(encoding="utf-8")

    # Read password
    pw_path = Path.home() / ".config" / "himalaya" / "virgilio.pass"
    if not pw_path.exists():
        print(f"Error: password file not found: {pw_path}", file=sys.stderr)
        sys.exit(1)

    pw = pw_path.read_text(encoding="utf-8").strip()

    # Build message
    msg = MIMEText(body, _charset="utf-8")
    msg["Subject"] = subject
    msg["From"] = from_addr
    msg["To"] = to_addr

    # Send via SMTP_SSL (port 465)
    context = ssl.create_default_context()
    try:
        with smtplib.SMTP_SSL("smtp.virgilio.it", 465, context=context) as server:
            server.login(from_addr, pw)
            server.send_message(msg)
    except Exception as e:
        print(f"SMTP_SSL failed: {e}", file=sys.stderr)
        sys.exit(2)

    print("OK — email sent", file=sys.stderr)
    sys.exit(0)


if __name__ == "__main__":
    main()
