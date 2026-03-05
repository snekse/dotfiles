# Contract: dotfiles-modernization

## Problem

There is no reproducible, automated system for provisioning a macOS developer workstation. Existing configs on the local machine (`.zshrc`, `.gitconfig`, aliases, etc.) are hand-maintained and would be lost or require tedious manual recreation when setting up a new Mac. A modern dotfiles system is needed before migrating to a new laptop.

## Goals

1. Build a new `dotfiles` repo (`~/dotfiles`) from scratch using GNU Stow for symlink management
2. Establish a Brewfile-driven package installation workflow
3. Provide a simple, discoverable bootstrap and install process via `just` + `install.sh`
4. Capture existing local machine configs into the repo via interactive AI-assisted review — modernizing and organizing them as they are migrated
5. Support multiple git identities (personal, business, occasional client) without branching the repo
6. Support clean deployment to a client-issued laptop via fork (one-way, no commits back)

## Success Criteria

- Running `install.sh` on a fresh Mac installs Homebrew + `just`, then `just install` completes the full setup without manual intervention
- All managed dotfiles are symlinked via Stow into `$HOME`
- `just update` upgrades Homebrew packages and language runtimes in one command
- Git identity switches automatically based on project directory via `includeIf`
- Each language version manager (SDKMAN, NVM, pyenv, rbenv) is installed and functional
- Starship prompt is configured and loading correctly in Zsh
- All configs reflect a deliberate, curated migration of the user's actual local machine configs

## Scope

### In

- New bare `dotfiles` repo, cloned to `~/dotfiles`
- `.stowrc` targeting `$HOME`
- Stow package structure (one directory per tool/topic)
- `install.sh` — bootstraps Homebrew + `just`, then delegates to Justfile
- `Justfile` — named targets: `install`, `link`, `update`, `unlink`
- `Brewfile` — CLI tools: git, stow, just, starship, fzf, ripgrep, and version manager dependencies
- `Brewfile.optional` — GUI apps (Cask) and App Store apps (mas); not run by default, requires explicit `just install-apps`
- Starship prompt config
- Zsh config (zshrc, zshenv, aliases, exports, functions)
- Git config with `includeIf` for per-directory identity switching
- SSH config with multiple Host aliases (not committed to repo — documented as manual step)
- Version manager setup scripts: SDKMAN, NVM, pyenv/pipenv, rbenv
- `macos.sh` — system defaults via `defaults write`
- Interactive AI-assisted config migration: read existing local machine configs (`~/.zshrc`, `~/.gitconfig`, etc.), propose modernized versions organized into the Stow package structure, and write them with user approval

### Out

- Vim, tmux, and Emacs configs (not part of daily workflow)
- 1Password integration (SSH agent, commit signing)
- Nix / Home Manager
- chezmoi, YADM, Dotbot, rcm, Mackup
- Custom `dot` CLI (replaced by `just` + `install.sh`)
- Automated client laptop provisioning (handled by forking, out of scope)
- Any config that cannot be symlinked (sandboxed app prefs like Magnet) — documented as manual steps
- Migration from `snekse/dot-files` repo (the old repo is not used; local machine configs are the source)

### Explicitly deferred

- GUI app configuration (IntelliJ, Chrome, etc.)
- Docker / Colima setup (see Stretch Goals)
- CI validation of the dotfiles repo
- Interactive TUI installer (see Stretch Goals)

## Stretch Goals

These are not in scope for the initial build but should be designed for — avoid architectural decisions that make them harder to add later.

### Interactive TUI Setup Script

An interactive terminal interface (using a tool like [`gum`](https://github.com/charmbracelet/gum) or `fzf`) that runs before package installation and allows selecting/deselecting individual items from each Brewfile section:

- Presents brews, casks, and mas apps as separate interactive checkbox lists
- Allows arrowing through and unchecking items not wanted on a specific machine (e.g., Spotify on a client laptop)
- Conducts an initial "interview" to generate `.local` override files:
  - `~/.gitconfig.local` (name, email, signing key for this machine)
  - Any other machine-specific overrides
- Docker/Colima install mode would be a question in this interview: "Docker Desktop, Colima, or skip?"
- Particularly valuable for client machine setup where a subset of the full install is appropriate

### Docker / Colima

- Docker Desktop for personal machines (when allowed)
- Colima as an alternative for environments where Docker Desktop is not permitted
- Selection of which to install handled by the interactive setup script when built
- Colima requires a LaunchAgent for autostart on boot

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Symlink manager | GNU Stow | Declarative, reversible, simple |
| Orchestration | `just` + `install.sh` | `install.sh` bootstraps `just`; Justfile provides discoverable targets |
| Prompt | Starship | Single binary, fast, easy to customize later |
| Packages | Homebrew + two Brewfiles | Core CLI tools always installed; apps/GUI optional |
| Multi-identity | `includeIf` in gitconfig | Auto-applies correct identity by directory |
| Secrets / SSH | Manual setup, not in repo | SSH config documented but not committed |
| Config migration | Interactive AI-assisted review | Local machine configs are the source of truth; migrated into Stow structure with modernization |
| Repo location | `~/dotfiles` | Conventional, Stow-friendly |

## Constraints

- Starting from a completely bare repo — no content from `snekse/dot-files` is carried over
- Local machine configs (`~/.zshrc`, `~/.gitconfig`, etc.) are the source of truth for migration
- SSH config stays out of the repo entirely — setup documented as a manual post-install step
- `Brewfile.optional` must require an explicit `just install-apps` invocation, never run automatically
- Config migration must be interactive — the AI agent proposes, the user decides
- Architecture should not preclude adding the interactive TUI installer as a future phase

## Execution Plan

### Dependency Graph

```
Phase 1 (Foundation)
  ├── Phase 2 (Shell & Prompt)
  │     └── Phase 4 (Language Runtimes)
  ├── Phase 3 (Git & Identity)
  └── Phase 5 (macOS Defaults)
```

### Execution Steps

Phases 2, 3, and 5 can run after Phase 1 in any order. Phase 4 depends on Phase 2 (needs shell config module system in place).

Each phase is an interactive Claude Code session focused on that spec. Start fresh sessions for each phase to keep context clean.

1. **Phase 1 — Foundation** (sequential, must be first)
   Start a new session in `~/dotfiles` and run:
   `/execute-spec docs/ideation/dotfiles-modernization/spec-phase-1.md`

2. **Phase 2 — Shell & Prompt** (after Phase 1)
   `/execute-spec docs/ideation/dotfiles-modernization/spec-phase-2.md`

3. **Phase 3 — Git & Identity** (after Phase 1, parallel with Phase 2)
   `/execute-spec docs/ideation/dotfiles-modernization/spec-phase-3.md`

4. **Phase 4 — Language Runtimes** (after Phase 2)
   `/execute-spec docs/ideation/dotfiles-modernization/spec-phase-4.md`

5. **Phase 5 — macOS Defaults** (after Phase 1, parallel with anything)
   `/execute-spec docs/ideation/dotfiles-modernization/spec-phase-5.md`
