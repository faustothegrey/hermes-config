# Hermes configuration and operational-memory backup

This repository backs up the relevant configuration for the Hermes Agent installation on `fausto-N56VV`.

## What is included

- `config/config.yaml` with secret-looking values redacted
- `config/SOUL.md` and other small Hermes config sidecars
- `skills/` for installed and agent-created Hermes skills
- `cron/` for Hermes scheduled jobs
- `profiles/` without per-profile plaintext secrets, runtime state, or installed binaries
- `plugins/`, `memories/`, `hooks/` when present
- `obsidian-vault/`, a copy of `/home/fausto/Documents/Obsidian Vault`
- `inventory/` command outputs useful during restore/debugging
- `scripts/backup-hermes.sh`, `scripts/generate-backup.py`, and `scripts/restore-hermes.sh`
- `secrets/*.enc`, encrypted secret/state bundle

## What is not committed in plaintext

- `~/.hermes/.env`
- `~/.hermes/auth.json`
- Google OAuth token/client-secret files
- gateway/pairing state
- `state.db`
- private SSH/GPG/API keys

Secrets can be committed only as encrypted artifacts under `secrets/*.enc`.
The current backup uses OpenSSL envelope encryption to the local SSH public key when `scripts/backup-hermes.sh` is run and an RSA SSH public key is available.

Important: if the machine crashes and the matching SSH private key is lost, encrypted secrets cannot be decrypted. Keep an offline copy of the private key, or migrate this repo to a long-term age/GPG recipient.

## Main operational harnesses in use

Hermes Agent:
- Main home: `~/.hermes`
- Config: `~/.hermes/config.yaml`
- Secrets/env: `~/.hermes/.env` encrypted into `secrets/hermes-secrets.tar.gz.enc`
- OAuth/credential pools: `~/.hermes/auth.json` encrypted into `secrets/hermes-secrets.tar.gz.enc`
- Skills: `~/.hermes/skills/`
- Cron jobs: `~/.hermes/cron/`
- Profiles: `~/.hermes/profiles/`
- Memories: `~/.hermes/memories/`

Obsidian operational memory:
- Vault path: `/home/fausto/Documents/Obsidian Vault`
- Backed up in repo as: `obsidian-vault/`
- Important folders: `Hermes/`, `Projects/`, `System/`, `Inbox/`
- Used for detailed operational/project notes that do not fit Hermes compact memory.

Git/GitHub backup harness:
- Repo: `git@github.com:faustothegrey/hermes-config.git`
- Local clone: `/home/fausto/Backups/hermes-config`
- Update command: `cd /home/fausto/Backups/hermes-config && scripts/backup-hermes.sh`

Gateway/voice/email harnesses:
- Gateway state/secrets are encrypted, not plaintext.
- Discord voice and email operational details are stored in Obsidian notes and copied under `obsidian-vault/`.
- Gmail is the default checking account; Virgilio is the configured sending account unless overridden.

External AI CLI harnesses:
- Claude Code, Antigravity, and Codex CLI availability/quotas are documented in Obsidian.
- Local quota helper: `/home/fausto/bin/ai-cli-quotas`.

## Routine backup

Run:

```bash
cd /home/fausto/Backups/hermes-config
scripts/backup-hermes.sh
```

That regenerates the sanitized snapshot, updates the encrypted secrets bundle, commits if there are changes, and pushes to GitHub.

## Restore

See `RESTORE.md` for the complete restore procedure.
