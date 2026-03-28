# Implementation Spec: Claude Settings Sync

**Contract**: ./contract.md
**Estimated Effort**: S

## Technical Approach

Create a `home/` stow package at the repo root — a general-purpose container for `~/.*` files that don't belong in an existing package. Add `home/.claude/settings.json` as its first resident. Stow will create a file-level symlink at `~/.claude/settings.json` pointing into the dotfiles repo; the rest of `~/.claude/` remains a real directory, keeping runtime data (sessions, cache, history) out of git.

Update `just link`, `just relink`, and `just unlink` to include the `home` package. Write a `bin/migrate-claude` script (borrowing Nick Nisi's dry-run pattern and live-wins logic, stripped to just `settings.json`) and a matching `just migrate-claude` recipe for one-time onboarding.

No new dependencies. No breaking changes to existing stow packages.

## Feedback Strategy

**Inner-loop command**: `stow --simulate home`

**Playground**: CLI / terminal

**Why**: stow's simulate mode prints exactly which symlinks would be created (or which conflicts exist) in under a second. Run it after any structural change to `home/` to validate before committing.

## File Changes

### New Files

| File Path | Purpose |
|---|---|
| `home/.claude/settings.json` | Tracked global Claude settings — initial resident of the `home/` stow package |
| `bin/migrate-claude` | One-time migration script: copies `~/.claude/settings.json` into dotfiles and re-stows |

### Modified Files

| File Path | Changes |
|---|---|
| `Justfile` | Add `home` to `link`, `relink`, `unlink` targets; add `migrate-claude` recipe |
| `README.md` | Add `just migrate-claude` to Commands table; add `migrate-claude` to Scripts table; note `home/` package |

## Implementation Details

### 1. `home/` stow package

Create the package directory and copy the live settings file as the initial committed value:

```
home/
  .claude/
    settings.json    ← copy of current ~/.claude/settings.json
```

**Pattern to follow**: `starship/` package — simple directory with one config file, no `.stow-local-ignore` needed.

No `.stow-local-ignore` required. Only files explicitly added to `home/` will be stowed; there's no risk of accidentally stowing an ignored file since the directory starts empty except for what we add.

**Implementation steps**:
1. `mkdir -p home/.claude`
2. Copy current `~/.claude/settings.json` → `home/.claude/settings.json`
3. Verify with `stow --simulate home` — should show `~/.claude/settings.json` → `~/dotfiles/home/.claude/settings.json`

**Feedback loop**:
- **Check command**: `stow --simulate home`
- **Expected output**: one symlink creation line for `settings.json`, no conflicts

---

### 2. `bin/migrate-claude`

Migration script for onboarding existing machines. Handles three states idempotently:

| State | Action |
|---|---|
| `~/.claude/settings.json` is already a symlink | No-op, exit 0 |
| Real file exists, dotfiles copy doesn't | Copy live → dotfiles, remove original, `just link` |
| Real file exists, dotfiles copy also exists (differs) | Live wins: overwrite dotfiles copy, remove original, `just link` |
| Real file exists, dotfiles copy also exists (identical) | Remove original (no copy needed), `just link` |
| Neither exists | No-op, exit 0 |

```bash
#!/usr/bin/env bash
# Migrate ~/.claude/settings.json into the dotfiles home/ package.
# Usage: bin/migrate-claude [-n|--dry-run]

set -Eeuo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SRC="$HOME/.claude/settings.json"
DEST="$DOTFILES/home/.claude/settings.json"

DRY_RUN=false
if [[ "${1:-}" == "-n" || "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  printf 'DRY RUN — no changes will be made\n\n'
fi

run() {
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Already a symlink — nothing to do
if [ -L "$SRC" ]; then
  printf '~/.claude/settings.json is already a symlink. Nothing to do.\n'
  exit 0
fi

# Source doesn't exist
if [ ! -f "$SRC" ]; then
  printf '~/.claude/settings.json does not exist.\n'
  if [ -f "$DEST" ]; then
    printf 'Dotfiles copy found — stowing...\n'
    run just -f "$DOTFILES/Justfile" link
  else
    printf 'Nothing to migrate.\n'
  fi
  exit 0
fi

# Create destination directory if needed
run mkdir -p "$(dirname "$DEST")"

# Sync — live wins if both exist and differ
if [ -f "$DEST" ]; then
  if ! diff -q "$SRC" "$DEST" &>/dev/null; then
    printf 'settings.json differs — live version wins, updating dotfiles copy...\n'
    run cp "$SRC" "$DEST"
  else
    printf 'settings.json is identical in live and dotfiles.\n'
  fi
else
  printf 'Copying ~/.claude/settings.json into dotfiles...\n'
  run cp "$SRC" "$DEST"
fi

# Remove the original real file so stow can create the symlink
printf 'Removing original ~/.claude/settings.json...\n'
run rm "$SRC"

# Stow
printf 'Linking home/ package...\n'
run just -f "$DOTFILES/Justfile" link

if [ "$DRY_RUN" = false ]; then
  printf '\nDone. ~/.claude/settings.json is now managed by dotfiles.\n'
  ls -la "$HOME/.claude/settings.json"
fi
```

Make executable: `chmod +x bin/migrate-claude`

**Feedback loop**:
- **Check command**: `bin/migrate-claude --dry-run`
- Preview the full migration without touching anything, then run without the flag to execute.

---

### 3. Justfile changes

Three existing targets gain `home`, one new recipe is added:

```just
# Stow all packages
link:
    stow zsh git starship home

# Restow all packages (use to apply structural changes without conflicts)
relink:
    stow --restow zsh git starship home

# Unstow all packages
unlink:
    stow -D zsh git starship home

# Migrate ~/.claude/settings.json into dotfiles and stow (run once per machine, -n for dry-run)
migrate-claude *args:
    bin/migrate-claude {{args}}
```

**Pattern to follow**: `Justfile:77-86` — existing `setup-ssh` and `setup-ssh-keys` recipes show the pattern for one-time setup targets that call `bin/` scripts.

---

### 4. README changes

**In the Commands section** — add one line after `just setup-ssh-config`:

```markdown
just migrate-claude     # Migrate ~/.claude/settings.json into dotfiles (run once per machine, use --dry-run to preview)
```

**In the Scripts section** — add one row to the table:

```markdown
| `migrate-claude` | One-time migration script that copies `~/.claude/settings.json` into the `home/` stow package, removes the original, and re-stows. Supports `--dry-run` (`-n`) to preview changes without modifying anything. |
```

**In the Stow: How Symlinks Work section** — add a brief note after the packages list about `home/`:

```markdown
The `home/` package is a general-purpose container for `~/.*` files that don't
belong in an existing package. It uses file-level stow (not directory-level),
so only explicitly tracked files land in git — runtime data in those directories
stays unmanaged.
```

## Testing Requirements

### Manual Testing

- [ ] `stow --simulate home` shows `~/.claude/settings.json` symlink, no conflicts
- [ ] `bin/migrate-claude --dry-run` prints the correct steps for your machine's current state
- [ ] After running `just migrate-claude`, `ls -la ~/.claude/settings.json` shows a symlink into `~/dotfiles/home/.claude/`
- [ ] `just unlink` removes the symlink cleanly; `just link` recreates it
- [ ] Running `just migrate-claude` a second time (already symlinked) exits cleanly with no-op message
- [ ] Editing `home/.claude/settings.json` in the repo is immediately reflected in Claude Code (no copy needed)

## Validation Commands

```bash
# Preview stow package structure
stow --simulate home

# Preview migration without changes
just migrate-claude --dry-run

# Run migration (once per machine)
just migrate-claude

# Verify result
ls -la ~/.claude/settings.json
# Expected: ~/.claude/settings.json -> ~/dotfiles/home/.claude/settings.json

# Verify re-link works
just unlink && just link && ls -la ~/.claude/settings.json
```

## Open Items

- None
