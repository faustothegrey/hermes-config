# Hermes configuration backup repository pattern

Use when the user asks to preserve a Hermes installation against machine loss by backing up `~/.hermes` into a Git repository.

## What to back up

Track these as plaintext/sanitized config:

- `config/config.yaml` with secret-like values redacted.
- `config/SOUL.md` and other non-secret top-level config helpers when present.
- `skills/` including support files and agent-created skills.
- `cron/` job definitions.
- `profiles/`, but exclude per-profile plaintext secrets, sessions, logs, runtime databases, caches, sandboxes, rollback snapshots, and installed binaries.
- `memories/` if the user wants operational/persona continuity and accepts the privacy tradeoff.
- `hooks/` and `plugins/` when present.
- `inventory/` command outputs for restore/debugging: `hermes config check`, `hermes tools list`, `hermes skills list`, `hermes profile list`, `hermes cron list`, and `hermes status --all`, all redacted.

Do not track plaintext:

- `~/.hermes/.env`
- `~/.hermes/auth.json`
- OAuth token/client-secret files such as `google_token.json` and `google_client_secret.json`
- gateway/pairing state
- `state.db` and session dumps unless explicitly requested and encrypted

## Recommended repo shape

```text
hermes-config/
  README.md
  RESTORE.md
  .gitignore
  config/
  skills/
  cron/
  profiles/
  memories/
  hooks/
  inventory/
  secrets/
    MANIFEST.json
    README.md
    hermes-secrets.tar.gz.enc
    hermes-secrets.key.enc
    hermes-secrets.key.pub
  scripts/
    generate-backup.py
    backup-hermes.sh
    restore-hermes.sh
```

## Secret handling

Prefer `age` or GPG if already configured. If only OpenSSL and SSH keys are available, an acceptable fallback is envelope encryption:

1. Create a tarball containing only secret files/directories.
2. Generate a random AES key.
3. Encrypt the tarball with AES-256-CBC + PBKDF2.
4. Convert the user's SSH public key to PKCS8 with `ssh-keygen -e -m PKCS8`.
5. Encrypt the AES key with `openssl pkeyutl -encrypt` using the converted public key.
6. Commit only the encrypted tarball, encrypted AES key, public key, and a manifest.
7. Verify decryption immediately into a temporary directory without touching the real `~/.hermes`.

Important pitfall: if the private key used for encryption is lost with the crashed machine, the encrypted secret bundle is unrecoverable. Tell the user to keep an offline copy of the matching private key or use a long-term encryption recipient stored elsewhere.

## Verification checklist

After creating or updating the repo:

1. Run `git status --short --branch` and `git ls-remote --heads origin <branch>` to prove local and remote match.
2. Use `git ls-files` to check no forbidden plaintext names are tracked: `.env`, `auth.json`, token files, raw `.tar.gz`, or profile `bin/` binaries.
3. Scan non-encrypted tracked text files for obvious secret patterns such as API-key prefixes, GitHub tokens, Bearer tokens, and private-key PEM headers. Ignore obvious documentation placeholders like `sk-xxxxxxxx`.
4. Test decrypt the encrypted secrets into a temp dir and list the tar members; do not restore over the live install during verification.
5. Report exact local path, remote URL, branch/commit hash, what is included, what is intentionally excluded, and the key recovery warning.

## Restore shape

A restore script should:

1. Create `~/.hermes`.
2. Copy sanitized non-secret config and directories into place.
3. Optionally decrypt and copy secrets if the matching private key is provided.
4. Run `hermes config check` and `hermes doctor`.
5. If secrets cannot be decrypted, instruct the user to re-run `hermes setup`, `hermes auth`, and platform-specific gateway setup.
