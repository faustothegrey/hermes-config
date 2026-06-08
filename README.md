# Hermes configuration backup

This repository backs up the relevant configuration for the Hermes Agent installation on `fausto-N56VV`.

Included:

- `config/config.yaml` with secret-looking values redacted
- `skills/`
- `cron/`
- `profiles/` without per-profile plaintext secrets, runtime state, or installed binaries
- `plugins/`, `memories/`, `hooks/` when present
- `inventory/` command outputs useful during restore/debugging
- `scripts/backup-hermes.sh` and `scripts/restore-hermes.sh`

Not committed in plaintext:

- `~/.hermes/.env`
- `~/.hermes/auth.json`
- Google OAuth token/client-secret files
- gateway/pairing state
- `state.db`

Secrets can be committed only as encrypted artifacts under `secrets/*.enc`.
The current backup uses OpenSSL envelope encryption to the local SSH public key when `scripts/backup-hermes.sh` is run and an RSA SSH public key is available.

Important: if the machine crashes and the matching SSH private key is lost, encrypted secrets cannot be decrypted. Keep a copy of the private key or use a different long-term encryption recipient.
