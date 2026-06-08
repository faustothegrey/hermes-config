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
- Operational note vaults that are part of the user's durable harness. For this user, `/home/fausto/Documents/Obsidian Vault` is small and important enough to back up as `obsidian-vault/`; include `.obsidian` UI/config files but exclude `.git`, `.trash`, logs, locks, and temp files.
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
  obsidian-vault/
    README.md
    Hermes/
    Projects/
    System/
    Inbox/
    .obsidian/
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

## Documentation expectations

The repo should include enough documentation that a future agent or the user can restore without re-reading the original chat:

- `README.md`: what is included, what is excluded from plaintext, how secrets are encrypted, routine backup command, and the main operational harnesses in use.
- `RESTORE.md`: step-by-step restore procedure, required tools, secret-key prerequisite, Hermes config restore, operational-vault restore, and verification commands.
- Main harness examples for this user: Hermes Agent (`~/.hermes`), Obsidian operational memory (`/home/fausto/Documents/Obsidian Vault`), Git/GitHub backup repo, gateway/voice/email notes, and external AI CLI quota tooling.

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
5. If an operational vault is backed up, smoke-restore it into a temp directory too and check for at least one expected note. Quote paths carefully: Obsidian vault paths often contain spaces, and unquoted environment assignments like `OBSIDIAN_VAULT_PATH=/tmp/Obsidian Vault ...` will fail.
6. Report exact local path, remote URL, branch/commit hash, what is included, what is intentionally excluded, and the key recovery warning.

## Restore shape

A restore script should:

1. Create `~/.hermes`.
2. Copy sanitized non-secret config and directories into place.
3. Restore selected operational vaults, e.g. `obsidian-vault/` to `${OBSIDIAN_VAULT_PATH:-$HOME/Documents/Obsidian Vault}`; allow path overrides via environment variables.
4. Optionally decrypt and copy secrets if the matching private key is provided.
5. Run `hermes config check` and `hermes doctor`.
6. If secrets cannot be decrypted, instruct the user to re-run `hermes setup`, `hermes auth`, and platform-specific gateway setup.
