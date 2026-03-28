# Claude Settings Sync Contract

**Created**: 2026-03-27
**Confidence Score**: 96/100
**Status**: Draft

## Problem Statement

Claude Code settings (`~/.claude/settings.json`) are not tracked in the dotfiles repo, so they diverge between machines. Adding a new model preference, enabling a plugin, or configuring a status line on one machine doesn't carry over to others. The only way to sync today is manual copy-paste.

The existing dotfiles repo already manages shell config, git identity, and prompt config via GNU Stow. Claude settings are the obvious next candidate — they follow the same pattern and would benefit from the same workflow.

## Goals

1. **Track `~/.claude/settings.json`** in the dotfiles repo so changes commit and sync like any other config file
2. **Use file-level stow** (not directory-level) so only explicitly tracked files land in git — runtime data (sessions, cache, history) stays out
3. **Establish `home/` as a general-purpose stow package** for `~/.*` files that don't belong in an existing package (`zsh/`, `git/`, `starship/`) — Claude settings are the first resident
4. **Provide a one-time migration target** (`just migrate-claude`) that safely moves an existing `~/.claude/settings.json` into the dotfiles repo before stowing

## Success Criteria

- [ ] `~/dotfiles/home/.claude/settings.json` exists and is tracked in git
- [ ] `~/.claude/settings.json` is a symlink pointing to `~/dotfiles/home/.claude/settings.json`
- [ ] `just link` stows the `home` package (including all future residents)
- [ ] `just unlink` unstows the `home` package
- [ ] `just migrate-claude` safely handles all three states: already symlinked, not yet migrated, settings.json missing
- [ ] `just migrate-claude --dry-run` previews all changes without touching the filesystem
- [ ] No Claude runtime files (sessions, cache, history, plugins) appear in `git status`
- [ ] README documents the `home/` package and `just migrate-claude`

## Scope Boundaries

### In Scope

- `home/` stow package directory (general-purpose, `~` target)
- `home/.claude/settings.json` — initial resident of the package
- `bin/migrate-claude` — migration script with dry-run support and live-wins logic
- `just migrate-claude` recipe calling the script
- Update `just link` and `just unlink` to include `home`
- README documentation for the new package and target

### Out of Scope

- Directory-level symlink for `~/.claude/` — runtime data (sessions, history, cache) must stay untracked
- Tracking `~/.claude/settings.local.json` — project-specific, not machine-global
- Tracking `~/.claude/commands/` globally — already managed per-project in repo-root `.claude/`
- Tracking `~/.claude/memory/` — potentially machine-specific context
- Adopting Nick Nisi's `dot` command CLI — the existing `just` + stow workflow is sufficient
- Any other `home/` package residents beyond Claude settings — future work

### Future Considerations

- Add other `~/.*` files to `home/` as needed (e.g., `~/.config/some-tool/config`)
- Evaluate tracking `~/.claude/commands/` globally once per-project vs. global command distinction is clearer
- Consider tracking `~/.claude/memory/` if cross-machine memory sync proves valuable

## Execution Plan

### Dependency Graph

```
Phase 1: Claude Settings Sync (single phase)
```

### Execution Steps

**Strategy**: Single phase, sequential

1. **Phase 1** — full implementation
   ```bash
   /execute-spec docs/ideation/claude-settings-sync/spec.md
   ```
