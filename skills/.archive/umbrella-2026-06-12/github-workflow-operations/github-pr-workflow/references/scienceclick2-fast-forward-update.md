# Direct fast-forward update for ScienceClick2

Use this when the user asks to "update ScienceClick2" without requesting feature work.

Context:

- Repo: `/home/fausto/Software/ScienceClick2`
- Default branch observed: `master`
- Remote: `origin`
- Project guidance: read `PROJECT.md` and `AGENTS.md` before acting.
- Package manager: npm with `package-lock.json`.

Recommended workflow:

```bash
cd /home/fausto/Software/ScienceClick2

# Preflight: confirm no local work would be overwritten
git status --short --branch

git fetch --prune origin
git status --short --branch
git log --oneline --decorate HEAD..origin/master || true
git log --oneline --decorate origin/master..HEAD || true

# Inspect what will change before pulling
git diff --stat HEAD..origin/master

# Only do this if the working tree is clean and the branch is simply behind
git pull --ff-only origin master

# Verify project health
npx tsc --noEmit
npm run lint
npm run build

# Final state
git status --short --branch
git log -1 --oneline --decorate
```

Notes:

- If `package.json` or `package-lock.json` changed during the pull, run `npm install` or `npm ci` as appropriate before verification. If they did not change and `node_modules` is already present, dependency reinstall is unnecessary.
- If the branch is not simply behind, stop and inspect divergence before pulling. Do not merge/rebase blindly.
- If the working tree has local edits, do not overwrite them. Report the files and ask or create a safe worktree/stash plan depending on the task.
- Verification defaults remain: TypeScript, lint, then production build.
