# Operational memory vs Obsidian

Use this when a Hermes operations session produces durable but detailed local knowledge: service notes, peer topology, CLI workflows, backup/restore details, troubleshooting recipes, or project conventions.

## Rule

Keep Hermes permanent memory compact. Store only:

- user preferences that should affect every future turn;
- fundamental paths needed to find the external knowledge base;
- short pointers to Obsidian notes;
- facts that must be visible in the prompt to prevent repeated mistakes.

Move the rest to Obsidian, especially:

- procedures longer than a few lines;
- config details and command recipes;
- troubleshooting history;
- one-machine service topology;
- peer status snapshots;
- backup/restore mechanics;
- session-specific operational findings.

## Recommended workflow

1. Identify the Obsidian vault path from memory or ask only if unavailable.
2. Create or update a class-level note rather than dumping a transcript.
   - Example: `Hermes/Peer Mesh.md` for peer topology and API status.
   - Example: `Hermes/External AI CLIs.md` for Claude/Codex/Antigravity workflows.
   - Example: `Hermes/Configuration Backup.md` for backup mechanics.
3. Add the note to an index such as `Hermes/Overview.md` so future sessions can find it quickly.
4. Redact or omit secrets; write only env var names and file paths for secret locations.
5. Compact memory entries to pointers like `Details live in Obsidian [[Hermes/Peer Mesh]]` plus only the bare essentials.
6. Verify by reading the updated index/note and checking memory usage after edits.

## Pitfalls

- Do not leave long command recipes in permanent memory when Obsidian is available.
- Do not store API keys, tokens, passwords, or connection strings in Obsidian or memory.
- Do not encode transient failures as durable rules. Capture the fix pattern or the final verified configuration.
- Avoid duplicating the same preference in both user profile and memory; keep one concise source.
