# AI CLI Quotas

## Script principale

Usare:

```bash
/home/fausto/bin/ai-cli-quotas
```

Lo script legge informazioni locali di utilizzo/quota per:

- Codex CLI;
- Claude Code CLI;
- Antigravity CLI.

## Codex

Codex può riportare quote da eventi `token_count` nei log JSONL locali in `~/.codex/sessions/**/*.jsonl`.

Se le date di reset sono nel passato, il campione è vecchio. In quel caso generare prima una micro-sessione fresca, ad esempio in una repo temporanea:

```bash
TMP=$(mktemp -d)
cd "$TMP"
git init -q
codex exec 'Reply exactly: OK'
/home/fausto/bin/ai-cli-quotas
```

## Claude Code

Lo script prova a catturare anche `/usage` interattivo tramite PTY/tmux quando possibile.

## Antigravity

Su `agy` 1.0.6 non risultano esposti token/quota percentuali locali; lo script riporta contatori di attività/richieste dai log locali.
