# Graphify semantic extraction via Claude Code CLI

Use this when evaluating or running Graphify on Markdown/docs/knowledge-base corpora without external LLM API keys.

## Key finding

Graphify has a built-in but under-advertised backend named `claude-cli`:

```bash
graphify extract <path> --backend claude-cli
```

It routes semantic extraction through the local Claude Code CLI (`claude -p --output-format json --no-session-persistence --system-prompt ...`) and uses the user's existing Claude Code subscription/OAuth auth instead of `ANTHROPIC_API_KEY` or another API key.

## When this matters

- Code-only Graphify extraction can run without an LLM backend because it uses AST/tree-sitter.
- Markdown/docs/PDF/images/video/knowledge-base corpora require semantic extraction and normally error if no API key is configured.
- `--backend claude-cli` satisfies that semantic backend requirement using local Claude Code CLI.

## Smoke-test pattern

Use a small corpus first, especially near system restart windows or quota-sensitive periods:

```bash
rm -rf /tmp/graphify-kb-smoke /tmp/graphify-kb-smoke-out
mkdir -p /tmp/graphify-kb-smoke/notes
cat > /tmp/graphify-kb-smoke/notes/example.md <<'EOF'
# Example KB

ScienceClick2 is an educational app for drag-and-drop labeling activities.
It uses scenes, draggable labels, target zones, and spectator mode.
EOF

graphify extract /tmp/graphify-kb-smoke \
  --backend claude-cli \
  --no-cluster \
  --out /tmp/graphify-kb-smoke-out \
  --token-budget 2000 \
  --max-concurrency 1
```

Verify output:

```bash
python - <<'PY'
import json, pathlib
p = pathlib.Path('/tmp/graphify-kb-smoke-out/graphify-out/graph.json')
d = json.loads(p.read_text())
print('nodes', len(d.get('nodes', [])), 'edges', len(d.get('edges', [])))
print([n.get('label') for n in d.get('nodes', [])[:20]])
PY
```

## Practical notes

- For docs/KB tests, keep `--max-concurrency 1` initially to avoid burning Claude quota or creating parallel CLI contention.
- Use `--token-budget` conservatively for small local smoke tests; increase only after confirming output quality.
- Output may include `tokens: ... est. cost: $0.0000` because billing goes through Claude Code subscription auth, not pay-as-you-go API usage.
- Graphify's CLI help may not list `claude-cli` even when the backend exists. Do not assume absence from help means absence from `graphify.llm.BACKENDS`.
- For code+docs corpora, Graphify will do AST extraction for code and Claude CLI semantic extraction for docs in the same run.

## Example ScienceClick2 micro-corpus result

A small ScienceClick2 smoke test with 3 TSX files plus `PROJECT.md`/`README.md` produced a graph with code nodes such as `SpectatorPage()`, `Canvas()`, `DropZone()`, `HeaderBar()`, plus documentation concepts such as `ScienceClick Application`, `Next.js 16`, `React 19`, `@dnd-kit/core`, and `Scenes`.

Use this as a sanity check shape, not as a fixed expected output.
