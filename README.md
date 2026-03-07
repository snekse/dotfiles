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
just relink          # Restow all packages (use after structural changes to resolve stale symlinks)
just unlink          # Unstow all packages
just install-apps    # Install optional GUI apps (casks, App Store)
just update          # Upgrade brew packages
just brew-check      # Check what brew bundle would change
just setup           # Interactive new-machine setup (zsh + git local configs)
just setup-zsh       # Write ~/.zshrc.local with DEV path and optional CONFLUENT_HOME
just setup-git       # Write ~/.gitconfig.local with name and email
just macos           # Apply macOS system defaults (run explicitly, never automatic)
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

**Gotcha — stow ignores `.gitignore` by default:** Stow's built-in default ignore list includes `.gitignore`, so a `git/.gitignore` package file will silently not be symlinked unless you override this. The fix is a `.stow-local-ignore` in the package directory — but note that creating one **replaces** the entire default list, so you must re-add any other defaults you still want (`.git`, `.gitmodules`, etc.). See [stow ignore list docs](https://www.gnu.org/software/stow/manual/html_node/Types-And-Syntax-Of-Ignore-Lists.html) and [issue #75](https://github.com/aspiers/stow/issues/75) for details. The `git/` package in this repo includes a `.stow-local-ignore` that handles this.

## Shell Functions

Custom functions are defined in `zsh/.config/zsh/` and auto-sourced by `.zshrc`.

### Homebrew (`brew.zsh`)

| Function | Description |
|---|---|
| `brew-add [-o] [--cask\|--tap\|--formula] <pkg>` | Add a package to the Brewfile, install it, and sync the repo (pull → install → commit → push). Auto-detects formula vs cask if no flag given. Pass `-o` to target `Brewfile.optional` instead. |
| `brew-remove <pkg>` | Uninstall a package and remove it from whichever Brewfile it lives in, then commit and push. Searches both Brewfiles, identifies type (formula/cask/tap/mas), and confirms before doing anything. |

### Filesystem & Network (`functions.zsh`)

| Function | Description |
|---|---|
| `mkcd <dir>` | Create a directory and `cd` into it in one step |
| `serve [port]` | Spin up a Python HTTP server in the current directory (default port 8000) |
| `port <number>` | Show all connections on a given port |
| `whatIsOnPort <number>` | Show processes listening on a given port (IPv4 TCP only) |

### Docker Compose (`functions.zsh`)

| Function | Description |
|---|---|
| `dcUp [file]` | Start all services in detached mode |
| `dcUpJust [file] <service>` | Start a single service without recreating dependencies |
| `dcPull [file]` | Pull updated images for all services |
| `dcDown [file]` | Stop and remove all containers, networks, and volumes |

## Manual Steps

These cannot be automated and must be done by hand:

### SSH Config

SSH config is not stored in this repo. Set up `~/.ssh/config` manually with your host aliases and keys.

### Git Identity

Run `just setup-git` to create `~/.gitconfig.local` with your machine-specific default identity (name and email). This file is never committed to the repo.

For multi-identity setups, the main `.gitconfig` uses `includeIf` to automatically load a different identity based on which directory a repo lives in:

```gitconfig
[includeIf "gitdir:~/dev/github/snekse/"]
  path = ~/.gitconfig-personal
```

This means any repo under `~/dev/github/snekse/` automatically gets the personal identity — no per-repo configuration needed. To add a work identity, copy `git/.gitconfig-work` to `~/.gitconfig-work`, fill in your details, and uncomment the matching `includeIf` block in `.gitconfig`.

`useConfigOnly = true` is set globally, which means git will error rather than silently use a wrong identity if no matching config is found for a repo. Always ensure repos live under a configured `includeIf` path or that `~/.gitconfig.local` exists as a fallback.

### App Store

Sign in to the App Store before running `just install-apps`. Uncomment any `mas` entries in `Brewfile.optional` that you want installed.

### Client Machine Setup

Fork this repo, clone your fork, then run `just install`. Remove or adjust entries in the Brewfiles as needed for the client environment.
