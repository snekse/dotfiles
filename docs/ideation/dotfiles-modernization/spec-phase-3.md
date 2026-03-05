# Spec: Phase 3 — Git & Identity

## Overview

Establish the Git configuration with multi-identity support via `includeIf`. Interactive AI-assisted review of existing git config (repo vs. local machine). The `.gitconfig.local` pattern handles machine-specific identity without branching the repo.

SSH config is explicitly **not** committed to the repo — this phase documents the manual setup pattern and creates a template for reference.

## Prerequisite

Phase 1 complete. `git/` Stow package directory exists in `~/dotfiles`.

---

## File Changes

### New files

```
~/dotfiles/
  git/
    .gitconfig
    .gitignore           # global gitignore
    .gitconfig-personal  # identity template (committed as example, not active)
    .gitconfig-work      # identity template (committed as example, not active)
  docs/
    ssh-setup.md         # manual SSH setup guide (not a Stow package)
```

### Not committed to repo

- `~/.gitconfig.local` — machine-specific identity, created manually post-install
- `~/.ssh/config` — SSH Host aliases, created manually post-install

---

## Implementation Details

### Interactive Config Review Process

Same methodology as Phase 2. Run in a Claude Code session:

1. **Read local machine configs:**
   - `~/.gitconfig`, `~/.gitignore`, `~/.gitconfig.local` (if it exists)
   - Any other git-related configs referenced via `[include]`

2. **Agent reviews and proposes modernized config:**
   - Core git settings (whitespace, color, branch, rebase)
   - Aliases — keep useful ones, flag stale or redundant ones
   - Diff/merge tool settings — update or keep based on what the user currently uses
   - `[include]` directives — organize into the new `includeIf` + `.gitconfig.local` pattern

3. **Agent flags:**
   - Any machine-specific settings (username, email, paths) that belong in `.gitconfig.local`
   - Any absolute paths
   - Settings that reference tools not in the Brewfile

### `.gitconfig`

```ini
[core]
  excludesfile = ~/.gitignore
  whitespace = fix
  autocrlf = input

[color]
  ui = auto
  branch = auto
  diff = auto
  status = auto

[branch]
  autosetupmerge = always
  autosetuprebase = local

[push]
  default = current

[pull]
  rebase = true

[rebase]
  autoStash = true

[rerere]
  enabled = true

[init]
  defaultBranch = main

[alias]
  co = checkout
  st = status -s
  br = branch --color
  lg = log --decorate --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative
  latest = for-each-ref --sort=-committerdate --format='%(committerdate:relative) -> %(refname:short)'
  undo = reset HEAD~1 --mixed
  aliases = config --get-regexp alias

# Multi-identity: applies config based on which directory the repo lives in.
# Add directories here that correspond to different identities.
# The paths must end with a trailing slash.
[includeIf "gitdir:~/personal/"]
  path = ~/.gitconfig-personal

[includeIf "gitdir:~/work/"]
  path = ~/.gitconfig-work

# Machine-specific overrides: name, email, signing key, etc.
# This file is NOT in the repo — created manually on each machine.
[include]
  path = ~/.gitconfig.local
```

**On `includeIf` directory convention:** This requires organizing repos under named directories (`~/personal/`, `~/work/`). Document this expectation in the README. The user has freelance/business work — a `~/work/` or `~/freelance/` directory makes the identity switch automatic.

### `.gitconfig-personal` (template, committed)

```ini
# Template: copy to ~/.gitconfig-personal and fill in
# This file IS in the repo as a reference — the actual file lives at ~/.gitconfig-personal
[user]
  name = Your Name
  email = you@personal.com
```

### `.gitconfig-work` (template, committed)

```ini
# Template: copy to ~/.gitconfig-work and fill in
[user]
  name = Your Name
  email = you@yourcompany.com
```

### `.gitconfig.local` (NOT in repo — manual step)

Document in README. Created on each machine:

```ini
# ~/.gitconfig.local — machine-specific, NOT committed to dotfiles repo
# Created manually after running just install
[user]
  name = Derek
  email = derek@example.com   # use the default identity for this machine
```

### `.gitignore` (global)

Review existing `vcs/git/gitignore` and modernize:

```gitignore
# macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
.AppleDouble
.LSOverride

# Editor
.vscode/
*.swp
*.swo
*~
.idea/

# Environment
.env
.env.local
.env.*.local

# Node
node_modules/
npm-debug.log*

# Python
__pycache__/
*.pyc
.venv/
.python-version

# Ruby
.bundle/

# Java
*.class
*.jar
target/

# OS
Thumbs.db
```

### `docs/ssh-setup.md`

Document the manual SSH setup pattern. This is reference documentation, not a Stow package.

```markdown
# SSH Setup

The SSH config is intentionally NOT committed to the dotfiles repo.
Create ~/.ssh/config manually after install.

## Pattern for multiple identities

Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  AddKeysToAgent yes

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  AddKeysToAgent yes

## Usage

Clone personal repos with:   git clone git@github-personal:username/repo.git
Clone work repos with:       git clone git@github-work:orgname/repo.git
```

---

## Update `Justfile`

```justfile
link:
    stow zsh starship git
```

---

## Post-Install Manual Steps (document in README)

```bash
# 1. Create ~/.gitconfig.local with your identity for this machine
cp ~/dotfiles/git/.gitconfig-personal ~/.gitconfig.local
# Edit it with your real name and email

# 2. Create ~/.ssh/config (see docs/ssh-setup.md)

# 3. Create your identity files if not already present:
# ~/.gitconfig-personal  (for ~/personal/ repos)
# ~/.gitconfig-work      (for ~/work/ repos)
```

---

## Validation

```bash
# Dry-run stow
stow --simulate git

# Apply stow
stow git

# Verify symlinks
ls -la ~/.gitconfig
ls -la ~/.gitignore

# Verify config resolves correctly
git config --global user.email     # should pull from .gitconfig.local
git config --list --show-origin    # shows which file each setting comes from

# Test includeIf (requires a repo in ~/personal/ or ~/work/)
cd ~/personal/some-repo
git config user.email              # should show personal email

cd ~/work/some-repo
git config user.email              # should show work email
```

## Feedback Loop

**Inner-loop command:** `git config --list --show-origin` — shows every resolved setting and which file it came from. Use this to verify `includeIf` is working and `.gitconfig.local` is being read.
