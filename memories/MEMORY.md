External AI CLIs: Claude Code, Antigravity, and Codex are installed/authenticated; usage checks use /home/fausto/bin/ai-cli-quotas. Details live in Obsidian [[Hermes/External AI CLIs]] and [[Hermes/AI CLI Quotas]].
§
Project ScienceClick2 lives at /home/fausto/Software/ScienceClick2; conventions are in PROJECT.md and Obsidian [[Projects/ScienceClick2]]. Prefer task-specific git worktrees for substantial implementation work.
§
System restarts daily at 00:00/06:00/12:00/18:00; avoid long tasks near restarts and checkpoint beforehand. Details in Obsidian [[System/Scheduled Restarts]].
§
Obsidian vault path is /home/fausto/Documents/Obsidian Vault; use it as external operational memory for detailed Hermes/project/system notes.
§
Discord voice and email operational details live in Obsidian [[Hermes/Discord Voice]] and [[System/Email]].
§
Graphify can perform semantic extraction through the local Claude Code CLI using `graphify extract <path> --backend claude-cli`, without external LLM API keys; useful for Markdown/KB corpora and mixed code+docs.
§
Sul setup dell'utente, Claude Code CLI può avviarsi in modalità interattiva/tmux ma non è necessariamente autenticato per generare: `claude -p` fallisce con 401 e anche l'interattivo, quando riceve un prompt, può rispondere `Please run /login · API Error: 401 Invalid authentication credentials`. Prima di deleghe Claude, verificare con un prompt interattivo reale o far completare `/login` all'utente.