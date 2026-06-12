# Tool / library repository evaluation reference

Use this when a user asks "what do you think of this repo/tool?" and the task is more than a LOC count.

## Recommended quick evaluation workflow

1. Clone to `/tmp/<repo>-review` with `git clone --depth 1` so the user's workspace is untouched.
2. Inspect top-level docs first: `README.md`, `ARCHITECTURE.md`, `SECURITY.md`, `pyproject.toml`/`package.json`/equivalent.
3. Gather repo health with the GitHub API if `gh` is unavailable; do not treat `gh: command not found` as a blocker:
   ```bash
   python3 - <<'PY'
   import json, urllib.request
   url='https://api.github.com/repos/OWNER/REPO'
   with urllib.request.urlopen(url, timeout=20) as r:
       d=json.load(r)
   print(json.dumps({k:d.get(k) for k in ['stargazers_count','forks_count','open_issues_count','default_branch','pushed_at','created_at']}, indent=2))
   print('license', (d.get('license') or {}).get('spdx_id'))
   PY
   ```
4. Do a composition pass (file counts/lines by extension or pygount when available) while excluding `.git`, build outputs, dependency dirs, and large example corpora.
5. Run non-invasive CLI checks (`--help`, version, dry-run commands) before installing anything globally.
6. If judging a CLI/library, create a temporary venv and/or tiny smoke fixture that exercises the claimed core feature. Prefer real CLI execution over only reading tests.
7. Interpret test failures carefully: missing dependencies, isolated checkout setup, or pytest-specific fixture/import behavior are not durable claims about the tool. Verify with a direct smoke test before concluding the feature is broken.
8. Report a balanced verdict: usefulness for the user's project, concrete positives, concrete risks, and a conservative adoption path (pilot output dir first; avoid global hooks until validated).

## Output pattern

- Start with the bottom-line verdict.
- Then bullets for: what it does, positives, cautions/red flags, fit for the user's project, recommended pilot commands.
- Explicitly distinguish "I verified this with a command" from "this is inferred from docs".
