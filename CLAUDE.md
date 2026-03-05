# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A macOS dotfiles repo using **GNU Stow** for symlink management, **just** for task orchestration, and **Homebrew** for package installation. The repo lives at `~/dotfiles` and symlinks configs into `$HOME`.

## Architecture

- **Stow packages**: Each top-level directory (e.g., `zsh/`, `git/`, `starship/`) is a Stow package. Files inside mirror their target location relative to `$HOME`.
- **Bootstrap flow**: `install.sh` installs Homebrew + `just`, then runs `just install` which stows packages and runs `brew bundle`.
- **Two Brewfiles**: `Brewfile` (core CLI tools, always installed) and `Brewfile.optional` (GUI apps/casks, only via `just install-apps`).
- **Git multi-identity**: Uses `includeIf` in gitconfig for per-directory identity switching.
- **Version managers**: SDKMAN and NVM installed via their own scripts (not Homebrew). pyenv and rbenv installed via Homebrew.

## Common Commands

```bash
just --list              # Show all available targets
just install             # Full install: stow packages + brew bundle
just link                # Stow all packages
just unlink              # Unstow all packages
just brew-install        # Install core CLI tools only
just install-apps        # Install optional GUI apps (explicit only)
just update              # Upgrade brew packages
just brew-check          # Check what brew bundle would change
stow --simulate <pkg>   # Dry-run stow to preview symlinks
stow -n <pkg>           # Same as --simulate
```

## Implementation Phases

The repo is being built incrementally per specs in `docs/ideation/dotfiles-modernization/`:

1. **Phase 1** — Foundation (repo structure, install.sh, Justfile, Brewfiles)
2. **Phase 2** — Shell & Prompt (zsh config, Starship)
3. **Phase 3** — Git & Identity (gitconfig with includeIf)
4. **Phase 4** — Language Runtimes (SDKMAN, NVM, pyenv, rbenv) — depends on Phase 2
5. **Phase 5** — macOS Defaults (defaults write scripts)

Phases 2, 3, 5 can run in parallel after Phase 1. Phase 4 depends on Phase 2.

## Key Constraints

- SSH config is **not committed** to the repo — documented as a manual post-install step
- `Brewfile.optional` must never run automatically; requires explicit `just install-apps`
- Config migration from the local machine is interactive — propose changes, user decides
- Secrets and credentials never go in the repo
- `.stowrc` sets `--target=~` so stow targets home regardless of repo location
