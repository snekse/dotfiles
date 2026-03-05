# Spec: Phase 1 — Foundation

## Overview

Establish the repo structure, bootstrap script, Justfile orchestration, and Brewfiles. No config content yet — this phase creates the skeleton that all other phases populate.

At the end of this phase, `install.sh` on a fresh Mac should install Homebrew and `just`, and `just install` should stow all empty packages and run `brew bundle`.

## Starting Condition

New bare repo already created and cloned to `~/dotfiles`. The repo is empty — all content is created from scratch. Existing local machine configs (`~/.zshrc`, `~/.gitconfig`, etc.) will be migrated into the repo in later phases.

---

## File Changes

### New files

```
~/dotfiles/
  .stowrc
  install.sh
  Justfile
  Brewfile
  Brewfile.optional
  README.md
  zsh/             # empty Stow package placeholder
  git/             # empty Stow package placeholder
  starship/        # empty Stow package placeholder
  install/         # version manager install scripts (populated in Phase 4)
```

---

## Implementation Details

### `.stowrc`

```
--target=~
```

This makes `stow <package>` work correctly regardless of where the repo lives (currently `~/dotfiles` — parent is already `~`, but explicit is better).

### `install.sh`

Bootstrap entry point. Must work on a fresh Mac before any tools are installed.

```bash
#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"

echo "==> Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon path fix
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

echo "==> Installing just..."
brew install just

echo "==> Running just install..."
cd "$DOTFILES" && just install
```

**Note on Apple Silicon:** Homebrew installs to `/opt/homebrew` on M-series Macs vs `/usr/local` on Intel. The `eval "$(/opt/homebrew/bin/brew shellenv)"` call is required within the same script session so subsequent `brew` calls resolve correctly.

### `Justfile`

```justfile
# List available targets
default:
    @just --list

# Full install: link dotfiles and install packages
install: link brew-install

# Stow all packages
link:
    stow zsh git starship

# Unstow all packages
unlink:
    stow -D zsh git starship

# Install core CLI tools
brew-install:
    brew bundle --file=Brewfile

# Install optional GUI apps and App Store apps (not run by default)
install-apps:
    brew bundle --file=Brewfile.optional

# Upgrade everything
update:
    brew update && brew upgrade
    brew bundle --cleanup --file=Brewfile

# Check what brew bundle would change
brew-check:
    brew bundle check --file=Brewfile
    brew bundle check --file=Brewfile.optional
```

**Design note for stretch goal:** The `install` target is intentionally simple now. When the interactive TUI installer is built (stretch goal), it will slot in before `link` and `brew-install` as a pre-flight step — either as `just setup` or by replacing `just install`. Keep `link` and `brew-install` as separate targets so the TUI can call them individually after the user has made selections.

### `Brewfile`

Core CLI tools only. Everything here installs on every machine without question.

```ruby
# Core
brew "git"
brew "stow"
brew "just"
brew "curl"
brew "wget"

# Shell
brew "zsh"
brew "starship"

# Search / navigation
brew "fzf"
brew "ripgrep"
brew "fd"
brew "bat"
brew "eza"          # modern ls replacement
brew "zoxide"       # smarter cd

# Development utilities
brew "jq"
brew "gh"           # GitHub CLI
brew "tree"
brew "htop"

# Version manager dependencies (managers themselves installed via scripts in Phase 4)
brew "rbenv"
brew "ruby-build"
brew "pyenv"
brew "pipenv"
```

**Note on NVM and SDKMAN:** These are not installed via Homebrew. NVM should be installed via its own install script (Homebrew NVM breaks auto-use). SDKMAN is installed via curl. Both are handled in Phase 4.

### `Brewfile.optional`

Not run by `just install`. Requires explicit `just install-apps`.

```ruby
# GUI Applications
cask "google-chrome"
cask "iterm2"
cask "visual-studio-code"
cask "intellij-idea"
cask "spotify"
cask "obsidian"
cask "slack"
cask "rectangle"    # window management (free alternative to Magnet)

# Fonts
cask "font-hack-nerd-font"
cask "font-fira-code-nerd-font"

# Mac App Store (requires: mas installed and App Store sign-in)
brew "mas"
# mas "Xcode", id: 497799835
# mas items commented out by default — uncomment what you want
```

**Pattern for stretch goal:** When the interactive TUI installer is built, it will read `Brewfile.optional` and present its entries as a checkbox list. Structure the file with clear section comments so the TUI parser can group them (brews, casks, mas). Avoid inline conditionals or complex Ruby in Brewfile.optional.

### `README.md`

Document the manual steps that cannot be automated:

1. SSH config setup (not in repo)
2. `~/.gitconfig.local` creation (name, email, signing key)
3. App Store sign-in before running `just install-apps`
4. What to do on a client machine (fork, clone, `just install`)

---

## Validation

After this phase:

```bash
# From ~/dotfiles
just --list                          # should show all targets
brew bundle check --file=Brewfile    # should show what would install
stow --simulate zsh                  # dry-run stow (nothing to link yet, but should not error)
./install.sh                         # should complete without errors on fresh machine
```

## Feedback Loop

**Inner-loop command:** `just --list` and `stow --simulate <package>`

No iterative components here — this phase is structural scaffolding. Validate by reading the generated files and running dry-run checks rather than executing install on your primary machine until you're confident.

**Safe testing approach:** Use `stow --simulate` (or `stow -n`) to preview what symlinks would be created before running for real.
