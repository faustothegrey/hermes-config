External AI CLIs: Claude Code, Antigravity, and Codex are installed/authenticated. Per Codex quota, usare solo `codex` interattivo `/status`; non usare parsing dei log Codex perché meglio nessun dato che dati stale. Details: Obsidian [[Hermes/External AI CLIs]]/[[Hermes/AI CLI Quotas]].
§
ScienceClick2 lives at /home/fausto/Software/ScienceClick2; conventions in PROJECT.md/Obsidian [[Projects/ScienceClick2]]. Prefer task worktrees for substantial work. Runtime server is already managed by system service `butler`; use it instead of starting duplicate dev servers.
§
System restarts daily at 00:00/06:00/12:00/18:00; avoid long tasks near restarts and checkpoint beforehand. Details in Obsidian [[System/Scheduled Restarts]].
§
Obsidian vault path is /home/fausto/Documents/Obsidian Vault; use it as external operational memory for detailed Hermes/project/system notes.
§
Discord voice and email operational details live in Obsidian [[Hermes/Discord Voice]] and [[System/Email]].
§
Graphify can perform semantic extraction through the local Claude Code CLI using `graphify extract <path> --backend claude-cli`, without external LLM API keys; useful for Markdown/KB corpora and mixed code+docs.
§
Hermes configuration backup repo is git@github.com:faustothegrey/hermes-config.git, cloned locally at /home/fausto/Backups/hermes-config. It backs up sanitized ~/.hermes config/skills/cron/profiles/memories and /home/fausto/Documents/Obsidian Vault, plus encrypted Hermes secrets using OpenSSL envelope encryption to /home/fausto/.ssh/id_rsa.pub; restore requires matching /home/fausto/.ssh/id_rsa or another configured SSH_PRIVATE_KEY.
§
Sul setup dell'utente, Claude Code CLI è delegabile in modalità interattiva via tmux: `claude` avvia la TUI, dopo workspace trust risponde correttamente a prompt reali. Preferire questa modalità per deleghe Claude. La modalità print `claude -p` va ancora smoke-testata separatamente prima dell'uso.
§
Sul setup dell'utente, Antigravity CLI `agy` è installato in `/home/fausto/.local/bin/agy`, versione 1.0.6, e la delega non interattiva print mode funziona: `agy -p 'Reply with exactly: antigravity-ok' --print-timeout 60s` restituisce `antigravity-ok`.