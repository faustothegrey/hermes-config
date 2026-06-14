# Hermes Configuration Backup

## Repository

The Hermes/local-knowledge backup repository is:

```text
git@github.com:faustothegrey/hermes-config.git
```

Local clone:

```text
/home/fausto/Backups/hermes-config
```

## Scope

The backup process is intended to cover:

- sanitized `~/.hermes` config;
- skills;
- cron jobs;
- profiles;
- memories;
- `/home/fausto/Documents/Obsidian Vault`;
- encrypted Hermes secrets.

## Secret encryption

Hermes secrets are backed up with OpenSSL envelope encryption to:

```text
/home/fausto/.ssh/id_rsa.pub
```

Restore requires the matching private key:

```text
/home/fausto/.ssh/id_rsa
```

or another explicitly configured `SSH_PRIVATE_KEY`.

## Runtime-output hygiene

The backup generator excludes cron runtime output (`cron/output/`) from the Git backup. Cron job definitions are backed up; historical watchdog output files are treated as runtime junk and should not be committed.

## Latest manual run

2026-06-14 manual run used the same nightly entrypoint:

```bash
/home/fausto/.hermes/scripts/hermes-config-backup-nightly.sh
```

Result:

- pushed `master` to GitHub;
- final verified commit: `6a1a902`;
- encrypted secrets bundle decrypt-smoke-test succeeded with `/home/fausto/.ssh/id_rsa`;
- no forbidden plaintext names tracked (`.env`, `auth.json`, token files, raw tarballs, `state.db`, profile `bin/`, or `cron/output/`).

## Memory policy

Permanent Hermes memory should only keep a short pointer to this note and the local clone path if needed. The details above belong here, not in prompt memory.
