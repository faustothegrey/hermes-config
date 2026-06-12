# Direct commit/push pattern from ScienceClick2

Use this reference when the user asks to commit and push already-reviewed changes directly to the current branch, rather than opening a PR.

## Context
- Repo: ScienceClick2 (`/home/fausto/Software/ScienceClick2`).
- User explicitly asked to commit and push all code changes after the fix had already passed typecheck, lint, and build.
- The correct workflow was direct commit to `master` and push to `origin/master`, not PR creation.

## Pattern
1. State delegation choice before acting, per user preference.
2. Check branch and working tree:
   - `git status --short --branch`
   - `git diff --stat`
   - `git diff --cached --stat`
3. Stage only the intended files, not the whole tree unless the user explicitly requests it.
4. Commit with a concise conventional commit message.
5. Push the current branch to its remote.
6. Verify with:
   - `git status --short --branch`
   - `git log -1 --oneline --decorate`
7. Report commit SHA, branch, remote, and clean/aligned status.

## Example
```bash
git status --short --branch
git diff --stat
git add src/app/scenes/[id]/page.tsx src/components/editor/WordList.tsx
git commit -m "fix: disable play drag after feedback"
git push origin master
git status --short --branch
git log -1 --oneline --decorate
```

## Pitfall
Do not turn a direct "commit and push" request into a PR workflow unless the user asks for a branch/PR or the repository policy requires it.