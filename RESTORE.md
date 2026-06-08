# Restore procedure

This file documents how to restore the Hermes Agent setup and the operational-memory harnesses backed up in this repository.

## 0. Critical prerequisite: secret decryption key

Encrypted secrets in `secrets/*.enc` were encrypted to the SSH public key from the original machine:

```text
/home/fausto/.ssh/id_rsa.pub
```

To restore `.env`, `auth.json`, OAuth tokens, gateway state, and `state.db`, you need the matching private key, usually:

```text
~/.ssh/id_rsa
```

If that key is lost, the plaintext configuration can still be restored, but secrets must be recreated with `hermes setup`, `hermes auth`, and gateway/platform setup.

## 1. Install base software on the new machine

Install Hermes Agent first:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

Required restore tools:

```bash
sudo apt-get update
sudo apt-get install -y git openssh-client openssl rsync
```

## 2. Clone this backup repo

```bash
mkdir -p ~/Backups
git clone git@github.com:faustothegrey/hermes-config.git ~/Backups/hermes-config
cd ~/Backups/hermes-config
```

If SSH to GitHub is not ready yet, add your GitHub SSH key first, or clone via HTTPS temporarily.

## 3. Restore Hermes config and secrets

For full restore with encrypted secrets:

```bash
cd ~/Backups/hermes-config
SSH_PRIVATE_KEY=~/.ssh/id_rsa scripts/restore-hermes.sh
```

For config-only restore without secrets:

```bash
cd ~/Backups/hermes-config
scripts/restore-hermes.sh
```

The script restores:

- `~/.hermes/config.yaml`
- `~/.hermes/skills/`
- `~/.hermes/cron/`
- `~/.hermes/profiles/`
- `~/.hermes/plugins/`
- `~/.hermes/memories/`
- `~/.hermes/hooks/`
- encrypted secrets/state, if the private key works

## 4. Restore Obsidian vault

The restore script also restores the vault backup from:

```text
obsidian-vault/
```

to:

```text
~/Documents/Obsidian Vault
```

Override the destination if needed:

```bash
OBSIDIAN_VAULT_PATH="/path/to/Obsidian Vault" scripts/restore-hermes.sh
```

After restore, open that folder as an Obsidian vault. The key operational notes are under:

- `Hermes/`
- `Projects/`
- `System/`
- `Inbox/`

## 5. Verify Hermes

Run:

```bash
hermes config check
hermes doctor
hermes tools list
hermes skills list
hermes profile list
hermes cron list
```

For gateway:

```bash
hermes gateway status
```

If needed:

```bash
hermes gateway setup
hermes gateway restart
```

## 6. Verify operational harnesses

Hermes Agent:

```bash
hermes config path
hermes status --all
```

Obsidian:

```bash
test -d "$HOME/Documents/Obsidian Vault" && find "$HOME/Documents/Obsidian Vault" -maxdepth 2 -type f | sort | head
```

External AI CLI quota helper, if restored/installed:

```bash
/home/fausto/bin/ai-cli-quotas || true
```

GitHub backup repo:

```bash
cd ~/Backups/hermes-config
git status --short --branch
git ls-remote --heads origin master
```

## 7. Recreate anything that cannot be decrypted

If encrypted secrets cannot be restored, recreate credentials manually:

```bash
hermes setup
hermes auth
hermes model
hermes gateway setup
```

Then run a fresh backup:

```bash
cd ~/Backups/hermes-config
scripts/backup-hermes.sh
```

## 8. Routine backup after restore

Once the machine is working again, update the backup with:

```bash
cd ~/Backups/hermes-config
scripts/backup-hermes.sh
```

This regenerates the Hermes snapshot, copies the Obsidian vault, refreshes the encrypted secrets bundle, commits changes, and pushes to GitHub.
