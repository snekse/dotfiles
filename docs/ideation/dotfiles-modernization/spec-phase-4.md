# Spec: Phase 4 — Language Runtimes

## Overview

Install and configure SDKMAN (Java/JVM), NVM (Node.js), pyenv + pipenv (Python), and rbenv (Ruby). Each runtime manager gets its own install script under `install/` and its own Zsh config module under `.config/zsh/`.

NVM requires lazy loading to avoid 500ms+ shell startup penalty. The others are fast enough to source directly.

## Prerequisite

Phase 2 complete. Zsh config module system (`~/.config/zsh/*.zsh`) is loading. `install/` directory exists in `~/dotfiles`.

---

## File Changes

### New files

```
~/dotfiles/
  install/
    sdkman.sh
    nvm.sh
    pyenv.sh
    rbenv.sh
  zsh/
    .config/
      zsh/
        sdkman.zsh     # replaces stub from Phase 2
        nvm.zsh        # replaces stub from Phase 2 — lazy loaded
        pyenv.zsh      # replaces stub from Phase 2
        rbenv.zsh      # replaces stub from Phase 2
```

---

## Implementation Details

### `install/sdkman.sh`

SDKMAN must be installed via curl, not Homebrew. The `ci=true` flag suppresses interactive prompts:

```bash
#!/usr/bin/env bash
set -e

if [[ -d "$HOME/.sdkman" ]]; then
  echo "==> SDKMAN already installed, skipping"
  exit 0
fi

echo "==> Installing SDKMAN..."
curl -s "https://get.sdkman.io?ci=true" | bash

# Source SDKMAN to use it immediately
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install default Java (LTS)
echo "==> Installing Java LTS..."
sdk install java

# Install additional candidates as needed
# sdk install gradle
# sdk install maven
# Uncomment or add versions based on your projects
```

**On version pinning:** The script installs the current LTS by default (`sdk install java` with no version = current default). For project-specific versions, use `.sdkmanrc` files in individual project directories (`sdk env init`).

### `install/nvm.sh`

NVM must be installed via git clone, not Homebrew. Homebrew NVM breaks the auto-use feature:

```bash
#!/usr/bin/env bash
set -e

NVM_DIR="$HOME/.nvm"

if [[ -d "$NVM_DIR" ]]; then
  echo "==> NVM already installed, skipping"
  exit 0
fi

echo "==> Installing NVM..."
# Install latest NVM (check https://github.com/nvm-sh/nvm for current version)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

source "$NVM_DIR/nvm.sh"

echo "==> Installing Node LTS..."
nvm install --lts
nvm use --lts
nvm alias default lts/*
```

**On version:** Check `https://github.com/nvm-sh/nvm/releases` for the current version tag before running. Update the version in the script.

### `install/pyenv.sh`

pyenv is installed via Homebrew (in `Brewfile`). This script sets up the default Python version:

```bash
#!/usr/bin/env bash
set -e

if ! command -v pyenv &>/dev/null; then
  echo "==> pyenv not found — run brew bundle first"
  exit 1
fi

echo "==> Installing Python (latest stable)..."
PYTHON_VERSION=$(pyenv install --list | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
pyenv install --skip-existing "$PYTHON_VERSION"
pyenv global "$PYTHON_VERSION"

echo "==> Installing pipenv..."
pip install --user pipenv
```

### `install/rbenv.sh`

rbenv is installed via Homebrew (in `Brewfile`). This script sets up the default Ruby version:

```bash
#!/usr/bin/env bash
set -e

if ! command -v rbenv &>/dev/null; then
  echo "==> rbenv not found — run brew bundle first"
  exit 1
fi

echo "==> Installing Ruby (latest stable)..."
RUBY_VERSION=$(rbenv install --list | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
rbenv install --skip-existing "$RUBY_VERSION"
rbenv global "$RUBY_VERSION"
```

### Add install scripts to Justfile

```justfile
# Install all language runtimes
install-runtimes: install-sdkman install-nvm install-pyenv install-rbenv

install-sdkman:
    bash install/sdkman.sh

install-nvm:
    bash install/nvm.sh

install-pyenv:
    bash install/pyenv.sh

install-rbenv:
    bash install/rbenv.sh
```

Update the main `install` target:

```justfile
install: link brew-install install-runtimes
```

Update the `update` target to include runtime upgrades:

```justfile
# Upgrade everything: Homebrew packages + language runtimes
update:
    brew update && brew upgrade
    brew bundle --cleanup --file=Brewfile
    -sdk selfupdate
    -sdk update
    -nvm install --lts --reinstall-packages-from=current
    -pyenv update || true
    -rbenv update || true
```

The `-` prefix in `just` means "don't fail if this command fails" — useful since not all runtimes may be installed on every machine.

### `zsh/.config/zsh/sdkman.zsh`

```zsh
# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

### `zsh/.config/zsh/nvm.zsh` — Lazy loaded

NVM init takes 500ms+. Lazy load it so it only initializes on first actual use:

```zsh
# NVM — lazy loaded for shell startup performance
export NVM_DIR="$HOME/.nvm"

# Lazy loader: initializes NVM on first use of node/npm/npx/nvm
_nvm_load() {
  unset -f node npm npx nvm yarn pnpm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

# Placeholder functions that trigger lazy load
node()  { _nvm_load; node  "$@"; }
npm()   { _nvm_load; npm   "$@"; }
npx()   { _nvm_load; npx   "$@"; }
nvm()   { _nvm_load; nvm   "$@"; }
yarn()  { _nvm_load; yarn  "$@"; }
pnpm()  { _nvm_load; pnpm  "$@"; }

# Auto-use .nvmrc when entering a directory (without initializing NVM at startup)
# This reads .nvmrc directly rather than calling `nvm use`, keeping startup fast
_nvm_auto_use() {
  local nvmrc_path
  nvmrc_path="$(pwd)/.nvmrc"
  if [[ -f "$nvmrc_path" ]]; then
    local nvmrc_node_version
    nvmrc_node_version=$(cat "$nvmrc_path")
    echo "Found .nvmrc: $nvmrc_node_version (run 'nvm use' to activate)"
  fi
}
add-zsh-hook chpwd _nvm_auto_use
```

**Note on prompt:** Starship auto-detects the Node version from `package.json`/`.nvmrc` without needing NVM initialized. The prompt stays fast.

### `zsh/.config/zsh/pyenv.zsh`

```zsh
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv &>/dev/null && eval "$(pyenv init -)"
```

### `zsh/.config/zsh/rbenv.zsh`

```zsh
# rbenv
command -v rbenv &>/dev/null && eval "$(rbenv init - zsh)"
```

---

## Validation

```bash
# Install runtimes
just install-runtimes

# SDKMAN
source ~/.sdkman/bin/sdkman-init.sh
sdk version
java --version

# NVM (triggers lazy load)
nvm --version
node --version
npm --version

# pyenv
pyenv --version
python --version
pipenv --version

# rbenv
rbenv --version
ruby --version

# Shell startup performance (should be under 200ms)
time zsh -i -c exit

# Verify NVM lazy loading doesn't slow startup
# (NVM should NOT appear in the time above — only loads on first node/npm use)
```

## Feedback Loop

**Inner-loop command:** `time zsh -i -c exit` — verifies shell startup time stays fast after adding each runtime config. Run after adding each `*.zsh` module to catch any that slow startup.

**NVM validation:** Open a new shell, time it, then type `node --version` and confirm it takes slightly longer (that's the lazy load) — expected behavior.
