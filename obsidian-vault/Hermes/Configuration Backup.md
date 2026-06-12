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

## Memory policy

Permanent Hermes memory should only keep a short pointer to this note and the local clone path if needed. The details above belong here, not in prompt memory.
