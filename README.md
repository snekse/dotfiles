# dotfiles

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), orchestrated by [just](https://github.com/casey/just), and powered by [Homebrew](https://brew.sh).

## Quick Start

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will install Homebrew and `just` if needed, then run `just install` to stow all packages and install core CLI tools.

## Commands

```bash
just                 # List all available targets
just install         # Full install: stow packages + brew bundle
just link            # Stow all packages
just unlink          # Unstow all packages
just install-apps    # Install optional GUI apps (casks, App Store)
just update          # Upgrade brew packages
just brew-check      # Check what brew bundle would change
```

## Stow: How Symlinks Work

Stow creates symlinks in `$HOME` pointing to files in each package directory. For example, `zsh/.zshrc` becomes `~/.zshrc -> ~/dotfiles/zsh/.zshrc`.

**Stow will never overwrite existing files.** If a real file already exists at the target location, stow will error out. You must back up and remove the existing file first, then run `just link`.

Use `stow --simulate <package>` (or `stow -n <package>`) to preview what symlinks would be created without actually creating them.

### Excluding Files from Linking

Not everything in a package directory needs to be symlinked. Stow supports two ways to exclude files:

**Per-package:** Create a `.stow-local-ignore` file inside any package directory with Perl regex patterns (one per line):

```
# zsh/.stow-local-ignore
\.gitkeep
README\.md
```

**Global:** Add `--ignore=pattern` to `.stowrc` to exclude across all packages. For example, `.gitkeep` files are excluded globally since they only exist to keep empty directories tracked in git.

## Manual Steps

These cannot be automated and must be done by hand:

### SSH Config

SSH config is not stored in this repo. Set up `~/.ssh/config` manually with your host aliases and keys.

### Git Identity

Create `~/.gitconfig.local` with your machine-specific identity:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
    signingkey = YOUR_KEY
```

The main gitconfig uses `includeIf` to switch identities by project directory.

### App Store

Sign in to the App Store before running `just install-apps`. Uncomment any `mas` entries in `Brewfile.optional` that you want installed.

### Client Machine Setup

Fork this repo, clone your fork, then run `just install`. Remove or adjust entries in the Brewfiles as needed for the client environment.
