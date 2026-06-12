# ScienceClick2 scene creation orchestration notes

Use this when delegating ScienceClick2 scene/config work to Claude Code after an external asset is available.

## Pattern

1. Controller reads project context first: `PROJECT.md`, `AGENTS.md`, and `skills/create-scene/skill.md`.
2. If the user has already confirmed Step 1 terms, tell Claude explicitly: "do not ask for term confirmation again".
3. Put substantial work in a task-specific worktree, but remember that `public/scenes/` may be gitignored; final scene files may need to be copied back and verified by path existence, not by `git status`.
4. Prompt Claude to create only `public/scenes/<category>/<scene-id>/config.json` when the image already exists. Include exact terms, required locales, target spacing rules, and verification script requirements.
5. After Claude finishes, the controller must independently verify:
   - image dimensions and path;
   - JSON syntax;
   - term/dropTarget one-to-one mapping;
   - all locales present and non-empty;
   - `agent` field present;
   - coordinates within 5..95;
   - no target pair closer than 8 percentage points on both axes;
   - API endpoint loads the new scene when feasible.
6. Inspect multilingual labels, especially Wolof, for suspicious hallucinations. Fix obvious bad translations before final reporting.

## TypeScript verification pitfall

If `node_modules` is missing, `npx tsc --noEmit` can install the wrong `tsc` package instead of using the project's TypeScript. Prefer:

```bash
npm install --prefer-offline
./node_modules/.bin/tsc --noEmit
```

or, when dependencies are already installed:

```bash
npx --no-install tsc --noEmit
```

Do not count a globally installed or auto-installed `tsc` shim as project verification.
