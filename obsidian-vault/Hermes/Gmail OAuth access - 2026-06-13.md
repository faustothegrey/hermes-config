# Gmail / Google Workspace OAuth access - 2026-06-13

## Context

Sessione Hermes del 13 giugno 2026. Fausto ha chiesto di verificare se Hermes avesse accesso al suo account email Google/Gmail e se il client OAuth esistente potesse essere usato anche per Google Drive, Calendar, Docs e Sheets.

## Risultato principale

Hermes non ha accesso funzionante a Gmail al momento, ma l'accesso OAuth era stato configurato in passato.

File token trovato:

```text
/home/fausto/.hermes/google_token.json
```

Account Google associato al setup locale:

```text
fausto.lelli@gmail.com
```

Il token contiene un refresh token, ma il refresh fallisce con:

```text
invalid_grant: Token has been expired or revoked.
```

Quindi:

- OAuth era configurato: sì
- token locale presente: sì
- refresh token presente: sì
- accesso Gmail attuale funzionante: no
- motivo: refresh token scaduto o revocato

La stessa situazione era già emersa in una sessione precedente dell'11 giugno 2026, con errore:

```text
TOKEN_REVOKED: invalid_grant: Token has been expired or revoked
```

## GNOME Online Accounts

È presente anche un account Google locale in GNOME Online Accounts:

```text
fausto.lelli@gmail.com
```

Mail/Calendar/Contacts/Drive ecc. risultano abilitati nella configurazione GOA, ma le credenziali non sono disponibili nel keyring.

Errore reale ottenuto da GOA:

```text
No credentials found in the keyring
```

Quindi anche GOA richiede re-login / re-autenticazione.

## Client secret

Non sembra necessario rigenerare client_id / client_secret.

L'errore `invalid_grant` indica un token revocato/scaduto, non un client secret errato.

Rigenerare il client secret serve solo se:

- il progetto Google Cloud o l'OAuth client è stato cancellato;
- il secret è stato ruotato/reset esplicitamente;
- Google Cloud segnala secret compromesso;
- si vuole cambiare progetto OAuth, tipo di app o consent screen.

La prossima azione consigliata è rifare il login OAuth, non rigenerare il secret.

## Scope attualmente presenti nel token vecchio

Il token attuale contiene solo:

```text
https://www.googleapis.com/auth/drive.readonly
https://www.googleapis.com/auth/gmail.readonly
```

Copertura del token vecchio:

- Gmail: sì, solo lettura
- Drive: sì, solo lettura
- Calendar: no
- Google Docs API: no
- Google Sheets API: no

## Google Workspace più ampio

È stato trovato nel backup Hermes uno script Google Workspace che prevedeva già scope più ampi:

```text
/home/fausto/Backups/hermes-config/profiles/cpia1/skills/productivity/google-workspace/scripts/setup.py
```

Lo script elenca servizi/scope per:

- Gmail read/send/modify
- Calendar
- Drive
- Contacts read-only
- Sheets
- Docs

Quindi il setup storico era pensato per Google Workspace, non solo Gmail.

## Scopes consigliati per nuovo login OAuth

Per ripartire in modo sicuro, meglio usare scope read-only quando possibile:

```text
https://www.googleapis.com/auth/gmail.readonly
https://www.googleapis.com/auth/drive.readonly
https://www.googleapis.com/auth/calendar.readonly
https://www.googleapis.com/auth/documents.readonly
https://www.googleapis.com/auth/spreadsheets.readonly
```

Se invece Fausto vuole permettere modifiche da Hermes:

```text
https://www.googleapis.com/auth/calendar
https://www.googleapis.com/auth/drive
https://www.googleapis.com/auth/documents
https://www.googleapis.com/auth/spreadsheets
```

Per inviare/modificare email Gmail:

```text
https://www.googleapis.com/auth/gmail.send
https://www.googleapis.com/auth/gmail.modify
```

Nota preferenza email già registrata altrove: controllare Gmail di default, inviare tramite Virgilio salvo diversa indicazione.

## Possibile causa ricorrente

Se il progetto OAuth Google è in modalità `Testing`, Google può far scadere i refresh token dopo circa 7 giorni. Se dopo il nuovo login il problema si ripresenta, controllare la OAuth consent screen in Google Cloud Console e valutare il passaggio a `Production`.

## Prossimi passi

1. Rifare login OAuth Google per Hermes usando il client secret esistente.
2. Richiedere gli scope necessari per Gmail + Drive + Calendar + Docs + Sheets.
3. Verificare con chiamate reali API:
   - Gmail: `users().getProfile(userId='me')` o lista 1 messaggio inbox
   - Drive: lista 1 file
   - Calendar: lista calendari o eventi
   - Docs: apertura/lettura di un documento noto o test minimo API
   - Sheets: apertura/lettura di uno spreadsheet noto o test minimo API
4. Se una API risponde che non è abilitata nel progetto Google Cloud, abilitare la relativa API; non rigenerare il secret.
5. Se il token si revoca/scade di nuovo dopo pochi giorni, verificare modalità Testing/Production del consent screen.

## Comandi / verifiche già eseguite

- Verifica Himalaya: installato, ma configurato solo per Virgilio.
- Verifica GOA tramite `gdbus`: account Google presente ma `AttentionNeeded=true` e credenziali mancanti.
- Verifica token Hermes con Python Google client: refresh fallito con `invalid_grant`.
- Ispezione sicura del token senza stampare segreti: scope vecchi solo `drive.readonly` e `gmail.readonly`.

## File correlati

```text
/home/fausto/.hermes/google_token.json
/home/fausto/.config/goa-1.0/accounts.conf
/home/fausto/Documents/Obsidian Vault/System/Email.md
/home/fausto/Backups/hermes-config/profiles/cpia1/skills/productivity/google-workspace/scripts/setup.py
```
