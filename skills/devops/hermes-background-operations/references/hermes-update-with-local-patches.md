# Hermes update with local patches

Use this reference when Hermes itself is git-installed and the user has local commits or an uncommitted patch that should survive an upstream `hermes update`.

## Goal

Preserve three recovery paths before changing the installed source:

1. A backup branch pointing at the pre-update HEAD.
2. Patch files for uncommitted/staged work under `~/.hermes/backups/`.
3. A git stash ref for uncommitted and untracked files.

Then update upstream `main`, create a fresh branch from the updated code, cherry-pick the local commits, reapply the stash, and verify.

## Preflight

```bash
cd ~/.hermes/hermes-agent
printf 'Local time: '; date '+%Y-%m-%d %H:%M:%S %Z'
git fetch origin --tags
git rev-parse --abbrev-ref HEAD
git status --short
git log --oneline origin/main..HEAD || true
git rev-list --left-right --count HEAD...origin/main || true
```

If the user prefers checkpointed/step-by-step work, stop after each major phase and report exact handles: branch name, patch paths, stash ref, and current `git status --short`.

## Save local state

```bash
stamp=$(date -u +%Y%m%d-%H%M%S)
mkdir -p ~/.hermes/backups
printf '%s' "$stamp" > ~/.hermes/backups/hermes-update-current-stamp.txt

backup_branch="backup/fausto-discord-voice-$stamp"   # rename prefix for other patch classes
git branch "$backup_branch" HEAD

git diff > ~/.hermes/backups/hermes-local-uncommitted-$stamp.patch
git diff --cached > ~/.hermes/backups/hermes-local-staged-$stamp.patch

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  git stash push --include-untracked -m "pre-hermes-update-$stamp"
  git rev-parse refs/stash > ~/.hermes/backups/hermes-stash-ref-$stamp.txt
else
  : > ~/.hermes/backups/hermes-stash-ref-$stamp.txt
fi

git status --short
```

Do not drop the stash until the user has verified the rebased branch.

## Update upstream main

```bash
git switch main
hermes update --backup --yes
```

`--backup` forces a pre-update Hermes Home backup. `--yes` avoids interactive migration/stash prompts, but do not use it if the user needs to answer update prompts manually.

## Recreate the local patch branch

```bash
stamp=$(cat ~/.hermes/backups/hermes-update-current-stamp.txt)
git switch -c "fausto/discord-voice-autojoin-rebased-$stamp"  # rename for other patch classes

git cherry-pick <local-commit-1>
git cherry-pick <local-commit-2>
```

On conflicts:

```bash
git status
# edit/resolve conflicted files
git add <resolved-files>
git cherry-pick --continue
# or abort the current commit with: git cherry-pick --abort
```

## Reapply uncommitted work

```bash
stamp=$(cat ~/.hermes/backups/hermes-update-current-stamp.txt)
stash_ref=$(cat ~/.hermes/backups/hermes-stash-ref-$stamp.txt)
if [ -n "$stash_ref" ]; then
  git stash apply "$stash_ref"
fi
```

Resolve conflicts normally. Keep the stash until tests pass and the user confirms. Only then:

```bash
git stash drop "$stash_ref"
```

## Verify

```bash
git status
hermes --version
python -m pytest tests/gateway/test_voice_command.py -q -o 'addopts='
```

Restart runtime after a successful code update:

```bash
hermes gateway restart
# or exit/reopen the CLI if only using foreground Hermes
```

## Pitfalls

- Do not run `git reset --hard` on the user's custom branch before creating a backup branch and patch/stash recovery path.
- Plain `hermes update` updates the install toward `main`; local feature branches remain in git but may no longer be the active runtime code.
- When local changes are gateway/Discord-related, preserve config separately from source code. Config in `~/.hermes/config.yaml` is not the same as repo patches.
- Long updates should not be started shortly before known reboot windows; checkpoint first and defer if needed.
