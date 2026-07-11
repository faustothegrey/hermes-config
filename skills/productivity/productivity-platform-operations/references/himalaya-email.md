# Himalaya Email — Session Detail

## Virgilio SMTP 451 Error (Jul 2026)

Observed on peer84 (N56VV) while trying to send from fausto.lelli@virgilio.it to fausto.lelli@gmail.com.

**Full error**:
```
Error:
   0: cannot connect to smtp server using tls
   1: Unexpected reply: Code: 451, Enhanced code: 0.0.0, Message: smtp-45.iol.local
      smtp-45.iol.local too many invalid recipients [smtp-45.iol.local; VIR_660]
```

**What worked**:
- IMAP auth to imap.virgilio.it:993 (TLS) — succeeded via Plain auth
- SMTP auth to smtp.virgilio.it:465 (TLS) — succeeded (password cmd returned code 0)
- Template generation via `himalaya template write -H "To:..." -H "Subject:..." "body"` — correct format
- A raw .eml approach via `himalaya message send` also reached the same error

**What failed**:
- SMTP delivery itself, with `451 too many invalid recipients`
- Same error even when sending to another @virgilio.it address (not just gmail)

**Verdict**: Server-side transient rejection. The "too many invalid recipients" language from Virgilio's SMTP suggests an account-level restriction (rate limit or temporary block), not a recipient-domain issue. Not a client configuration problem.

**Reproduction**: All of the above occurred within a 2-minute window. A single retry after a 2-second delay produced the same error.

## Command syntax discovered

Commands tried and their outcomes:

| Command | Result |
|---|---|
| `himalaya send ...` | `error: unrecognized subcommand 'send'` |
| `himalaya message send --subject ...` | `error: unexpected argument '--subject' found` |
| `himalaya message send` + piped raw email | Reached SMTP (got 451) — structurally valid |
| `himalaya template write -H "To:..." -H "Subject:..." "body" \| himalaya template send` | Reached SMTP (got 451) — preferred approach |
| `himalaya template write` + `template send` with `-a virgilio` | Same 451 — explicit account doesn't change outcome |

## Password auth

The auth script at `/home/fausto/.config/himalaya/virgilio-password` reads the first line of `/home/fausto/.config/himalaya/virgilio.pass` and prints it. Works correctly (tested: returned password, exit code 0).

## Folder aliases

For Virgilio:
- `inbox` → `INBOX`
- `sent` → `Posta Inviata`
- `drafts` → `Bozze`
- `trash` → `Cestino`