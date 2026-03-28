# Context Map: claude-settings-sync

**Phase**: 1
**Scout Confidence**: 97/100
**Verdict**: GO

## Dimensions

| Dimension | Score | Notes |
|---|---|---|
| Scope clarity | 20/20 | All four change targets fully understood: `home/.claude/settings.json` (new), `bin/migrate-claude` (new, full script body in spec), `Justfile` (three line edits + one new recipe, exact text in spec), `README.md` (three insertion points identified, exact text in spec) |
| Pattern familiarity | 20/20 | `starship/` package read (single-file, no `.stow-local-ignore`). `bin/claude-statusline` read. Justfile recipe style confirmed at lines 77-86. `.stowrc` confirms `--target=~` and `--ignore=\.gitkeep`. |
| Dependency awareness | 19/20 | `Justfile` link/relink/unlink lines are standalone; no other file imports or calls them except `install.sh` calling `just install`. README changes are additive. The `.gitignore` entry `.claude/*` is critical — the `home/` package lives at repo root nested under `home/`, not under top-level `.claude/`, so no conflict. |
| Edge case coverage | 19/20 | Spec covers all migration states: already-symlinked (no-op), real file only, both exist (differ — live wins), both exist (identical), neither exists. |
| Test strategy | 19/20 | Manual test sequence fully specified in spec. Key commands: `stow --simulate home`, `bin/migrate-claude --dry-run`, `ls -la ~/.claude/settings.json`, round-trip unlink/link. |

## Key Patterns

- `/Users/derek/dotfiles/starship/.config/starship.toml` — Single file inside a single subdirectory. No `.stow-local-ignore`. `home/` follows same shape: one file at `home/.claude/settings.json`.
- `/Users/derek/dotfiles/bin/claude-statusline` — `#!/usr/bin/env bash` shebang, lives in `bin/` which is on `$PATH`. Must be made executable with `chmod +x`.
- `/Users/derek/dotfiles/Justfile:11-20` — `link`, `relink`, `unlink` are single-line stow calls. Adding `home` is a simple append to each.
- `/Users/derek/dotfiles/Justfile:77-86` — one-time setup recipes calling `bin/` or `install/` scripts. New `migrate-claude` recipe uses `*args` variadic syntax.

## Dependencies

- `Justfile:11` (`link`) — consumed by → `install` recipe (line 8), `bin/migrate-claude` (calls `just -f "$DOTFILES/Justfile" link`)
- `Justfile:15` (`relink`) — consumed by README Commands section only
- `Justfile:19` (`unlink`) — consumed by README Commands section only
- `README.md` — documentation only, no code consumers
- `home/.claude/settings.json` — consumed by stow (via link/relink/unlink) and Claude Code at runtime via symlink

## Conventions

- **Naming**: Stow packages are lowercase at repo root (`zsh`, `git`, `starship`, `home`). Bin scripts are kebab-case. Justfile recipes are kebab-case.
- **Stow package structure**: Files mirror path relative to `~`. No `.stow-local-ignore` needed for `home/`.
- **README structure**: Commands section is a single fenced bash block (lines 24-43). Scripts section is a markdown table (lines 117-118). `just migrate-claude` goes after `just setup-ssh-config`; `migrate-claude` row goes after `claude-statusline`.
- **Bin scripts**: Made executable via `chmod +x`. `bin/` already on `$PATH`.

## Risks

- **`.gitignore` pattern `.claude/*`** at line 2 — matches top-level `.claude/` only. `home/.claude/` is nested and tracked correctly. Verify with `git status` after creating the file.
- **Stow conflict** — `~/.claude/settings.json` currently exists as a real file. Running `just link` before migration will error. Migration must run first.
- **`$DOTFILES` env var** defaults to `$HOME/dotfiles`. If repo is elsewhere, script will fail. Known limitation per spec.
- **`*args` variadic syntax** in `migrate-claude` recipe — new for this Justfile but valid just syntax.
