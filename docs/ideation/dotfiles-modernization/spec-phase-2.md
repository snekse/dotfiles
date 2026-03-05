# Spec: Phase 2 — Shell & Prompt

## Overview

Establish the Zsh configuration and Starship prompt via an interactive AI-assisted review. The AI agent reads the user's existing local machine configs (`~/.zshrc`, `~/.zshenv`, etc.), proposes modernized versions organized into the Stow package structure, and writes them with user approval.

At the end of this phase, `just link` should symlink the Zsh and Starship packages, and a new shell session should load correctly with the Starship prompt.

## Prerequisite

Phase 1 complete. `zsh/` and `starship/` Stow package directories exist in `~/dotfiles`.

---

## File Changes

### New files

```
~/dotfiles/
  zsh/
    .zshrc
    .zshenv
    .config/
      zsh/
        aliases.zsh
        exports.zsh
        functions.zsh
        path.zsh
        rbenv.zsh       # populated in Phase 4, stub here
        nvm.zsh         # populated in Phase 4, stub here
        pyenv.zsh       # populated in Phase 4, stub here
        sdkman.zsh      # populated in Phase 4, stub here
  starship/
    .config/
      starship.toml
```

---

## Implementation Details

### Interactive Config Review Process

This is the core methodology for this phase. Run in a Claude Code session:

1. **Read the local machine configs:**
   - `~/.zshrc`, `~/.zshenv`, `~/.zprofile` (if they exist)
   - `~/.zsh_aliases`, `~/.bash_aliases`, or any sourced alias files
   - Any other shell config files sourced by the above

2. **For each config section, the agent:**
   - Shows what's currently on the local machine
   - Proposes a modernized version organized into the new modular Stow structure
   - Notes what's being kept, what's being updated, and what's being dropped (with reasons)
   - Waits for user confirmation before writing

3. **The agent should flag:**
   - Anything referencing tools not in the Brewfile
   - PATH entries for directories that may not exist on the new machine
   - Anything that belongs in a `.local` file rather than the shared config
   - Stale aliases or functions the user may no longer need

### `.zshrc` structure

```zsh
# ~/.zshrc — loaded for interactive shells

# XDG base dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

DOTFILES="$HOME/dotfiles"
ZSH_CONFIG="$XDG_CONFIG_HOME/zsh"

# Source all zsh config modules
for config in "$ZSH_CONFIG"/*.zsh; do
  source "$config"
done

# Machine-local overrides (not in repo)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Prompt
eval "$(starship init zsh)"
```

**Note:** Language runtime sourcing (nvm, sdkman, pyenv, rbenv) goes in their own `*.zsh` files under `.config/zsh/` — stubbed here, completed in Phase 4.

### `.zshenv` structure

```zsh
# ~/.zshenv — loaded for ALL zsh sessions (login, interactive, scripts)
# Keep this minimal. Only things that must be available everywhere.

export EDITOR="$(command -v vim || command -v nano)"
export VISUAL="$EDITOR"
export DOTFILES="$HOME/dotfiles"
```

**Warning:** Do not put PATH manipulation or slow commands in `.zshenv` — it loads for every shell including scripts.

### `exports.zsh`

```zsh
export TERM="xterm-256color"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# History
export HISTSIZE=1000000
export HISTFILESIZE=1000000
export HISTFILE="$HOME/.zsh_history"
export HISTIGNORE="clear:bg:fg:cd:cd -:exit:date:w:* --help"

# Color
export CLICOLOR=1
export GREP_COLOR='1;32'
```

### `path.zsh`

Build PATH cleanly, checking for directory existence before adding:

```zsh
# Build PATH from scratch, only including existing directories
typeset -U path  # zsh: auto-deduplicate

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$DOTFILES/bin"
  /opt/homebrew/bin    # Apple Silicon
  /opt/homebrew/sbin
  /usr/local/bin       # Intel
  /usr/local/sbin
  /usr/bin
  /usr/sbin
  /bin
  /sbin
)

# Filter to only directories that exist
path=("${(@)path:#}" ${^path}(N-/))
export PATH
```

### `aliases.zsh`

Review the user's existing aliases from their local machine. Propose modernized versions using tools from the Brewfile. Start with these modern substitutions as defaults:

```zsh
# Navigation
alias ll='eza -lah --git'    # requires eza in Brewfile
alias l='eza'
alias b='cd -'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts (from existing git.sh — keep what you actually use)
alias gs='git status -s'
alias ga='git add'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gco='git checkout'
alias gl='git pull --rebase'
alias gp='git push'
alias gb='git branch --color'
alias gd='git diff'
alias glg="git log --decorate --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"

# Utilities
alias jsonify='jq .'          # requires jq
alias pubkey='cat ~/.ssh/*.pub'

# macOS
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
```

**During review:** Flag any aliases referencing tools or workflows the user no longer uses.

### `functions.zsh`

Review the user's existing shell functions from their local machine. Propose keepers and suggest useful additions:

```zsh
# Create directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Find process using a port
port() { lsof -i ":${1:?Usage: port <number}"; }

# Quick HTTP server in current directory
serve() { python3 -m http.server "${1:-8000}"; }
```

### `starship.toml`

Starship config at `~/.config/starship.toml`. Start with a clean, minimal config and customize from there:

```toml
# ~/.config/starship.toml

format = """
$directory\
$git_branch\
$git_status\
$nodejs\
$python\
$ruby\
$java\
$line_break\
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[$symbol$branch]($style) "

[git_status]
format = '([$all_status$ahead_behind]($style) )'

[nodejs]
format = "[$symbol($version)]($style) "

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
```

**Note:** Starship auto-detects Node, Python, Ruby, Java versions in the current directory from lockfiles/version files — no manual version manager integration needed in the prompt config.

---

## Update `Justfile`

Add the stow packages to the `link` and `unlink` targets as they are created. After Phase 2:

```justfile
link:
    stow zsh starship
```

---

## Validation

```bash
# Dry-run stow
stow --simulate zsh
stow --simulate starship

# Apply stow
stow zsh starship

# Verify symlinks
ls -la ~/.zshrc          # should point to ~/dotfiles/zsh/.zshrc
ls -la ~/.config/starship.toml

# Start new shell session
zsh

# Verify prompt loads
starship --version
echo $DOTFILES           # should print ~/dotfiles
echo $PATH               # should include Homebrew and local bin dirs

# Verify aliases loaded
type ll
type gs
```

## Feedback Loop

**Inner-loop command:** Open a new `zsh` tab/session after changes and verify the prompt loads without errors.

**Config review sessions:** Work through one config file at a time in Claude Code. Read the local machine version, propose a modernized replacement, confirm the output before writing. Do not batch multiple config files into one review — context gets noisy.
