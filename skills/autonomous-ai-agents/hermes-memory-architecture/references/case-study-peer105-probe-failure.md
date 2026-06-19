# Case Study: Peer105 — When Not to Probe Live

**Date:** 2026-06-19
**Session context:** User asked about peer105/106 system specs for resource monitoring.

## What happened

Agent's first instinct was to probe peer105 live via `call_peer` and `start_peer_run` APIs. Failed 3 times with:
```
Error code: 404 - Model 'nvidia/nemotron-3-ultra:free' not found.
```

Agent also tried SSH to 192.168.178.105 — permission denied.

## What was already known

All peer specs were documented in the Obsidian vault at:
- `~/Documents/Obsidian Vault/Hermes/Peer105 YouTube.md` lines 24-30
- `~/Documents/Obsidian Vault/Hermes/Peer106 Web Research.md` lines 23+

The vault also revealed WHY peer105 was broken: on June 14 (Loop #2), peer106 had already been migrated to `deepseek/deepseek-chat` after nemotron was removed. Peer105 was still on the old model.

## Root cause

Agent skipped the memory layers and went straight to live probes. A 2-second `search_files` on the vault would have found everything.

## Lesson

Always check memory layers before live probes: HOT → WARM → COLD → VAULT → only then probe live.
