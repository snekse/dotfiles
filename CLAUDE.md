# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A macOS dotfiles repo using **GNU Stow** for symlink management, **just** for task orchestration, and **Homebrew** for package installation. The repo lives at `~/dotfiles` and symlinks configs into `$HOME`.

## Architecture

- **Stow packages**: Each top-level directory (`zsh/`, `git/`, `starship/`) is a Stow package. Files inside mirror their target location relative to `$HOME`.
- **Bootstrap flow**: `install.sh` installs Homebrew + `just`, then runs `just install` which stows packages, runs `brew bundle`, and installs language runtimes.
- **Two Brewfiles**: `Brewfile` (core CLI tools + casks, always installed) and `Brewfile.optional` (GUI apps/fonts/MAS apps, only via `just install-apps`).
- **Git multi-identity**: Uses `includeIf` in gitconfig for per-directory identity switching. Fallback identity in `~/.gitconfig.local` (not in repo, created by `just setup-git`).
- **Machine-local config**: `~/.zshrc.local` holds machine-specific env vars (e.g. `$DEV`, `$CONFLUENT_HOME`). Created by `just setup-zsh`. Not committed.
- **Version managers**:
  - **Java**: SDKMAN installed via `install/sdkman.sh`
  - **Node**: NVM installed via `install/nvm.sh`; pnpm installed via Homebrew
  - **Ruby**: rbenv installed via Homebrew + `install/rbenv.sh`
  - **Python**: uv (installed via Homebrew) handles versions, venvs, and deps
- **Zsh config modules**: `~/.config/zsh/*.zsh` files are sourced automatically by `.zshrc`. Each runtime (nvm, rbenv, sdkman, uv) has its own module.
- **`.stowrc`**: sets `--target=~` so stow targets home regardless of repo location.

## Common Commands

```bash
just --list              # Show all available targets
just install             # Full install: stow packages + brew bundle + runtimes
just link                # Stow all packages (zsh git starship)
just unlink              # Unstow all packages
just brew-install        # Install core CLI tools only
just install-apps        # Install optional GUI apps (explicit only)
just install-runtimes    # Install SDKMAN + NVM + rbenv
just update              # Upgrade brew packages + update runtimes
just brew-check          # Check what brew bundle would change
just macos               # Apply macOS system defaults (explicit, not part of install)
just setup               # Machine-local setup: writes ~/.zshrc.local + ~/.gitconfig.local
just setup-zsh           # Write ~/.zshrc.local (DEV path, CONFLUENT_HOME, etc.)
just setup-git           # Write ~/.gitconfig.local (git name + email)
stow --simulate <pkg>    # Dry-run stow to preview symlinks
stow -n <pkg>            # Same as --simulate
```

## Post-Install Steps (manual)

After `just install`, run on each new machine:

1. `just setup` — create `~/.zshrc.local` and `~/.gitconfig.local`
2. `just macos` — apply macOS defaults (optional, review first)
3. Configure SSH keys manually (not in repo)

## Key Constraints

- SSH config is **not committed** to the repo — documented as a manual post-install step
- `Brewfile.optional` must never run automatically; requires explicit `just install-apps`
- `just macos` must never run automatically; requires explicit invocation
- `~/.zshrc.local` and `~/.gitconfig.local` are not committed — created by `just setup`
- Secrets and credentials never go in the repo
