# install/

Scripts run during machine bootstrap, called by `justfile` targets or directly from `install.sh`.

## Scripts

| Script | Just target | Description |
|--------|-------------|-------------|
| `sdkman.sh` | `just install-sdkman` | Install SDKMAN (Java version manager) |
| `nvm.sh` | `just install-nvm` | Install NVM and Node LTS |
| `rbenv.sh` | `just install-rbenv` | Install rbenv and a default Ruby version |
| `configure_ssh.sh` | `just setup-ssh-keys` | Generate an ed25519 SSH key and verify GitHub connectivity |
| `configure_ssh_config.sh` | `just setup-ssh-config` | Interactively build or update `~/.ssh/config` |

## Known Bootstrap Issues

### SSH URL override conflicts

`git/.gitconfig` contains:

```gitconfig
[url "git@github.com:"]
  insteadOf = https://github.com/
```

This rewrites all HTTPS GitHub URLs to SSH. It becomes active as soon as `just link` runs (stow) — before SSH keys are configured on a new machine. Any tool that uses `git clone https://github.com/...` internally will fail with "Permission denied (publickey)".

`install.sh` handles this by running `install/configure_ssh.sh` between `just link` and `just install-runtimes`, giving the user a chance to generate and register an SSH key before runtimes are installed.

**Known affected tools and their fixes:**

| Tool | Problem | Fix |
|------|---------|-----|
| NVM installer | `git clone https://github.com/nvm-sh/nvm.git` gets rewritten to SSH | `METHOD=script` env var forces curl-based install (see `install/nvm.sh`) |

**If another tool fails with a publickey SSH error:**

Two options:

1. **Fix at the tool level** (preferred): check if the installer has a flag or env var to force HTTPS/curl instead of git (like `METHOD=script` for NVM).

2. **Add a scoped URL override** in `git/.gitconfig`:
   ```gitconfig
   [url "https://github.com/<org>/"]
     insteadOf = https://github.com/<org>/
   ```
   Git's longest-match rule means this no-op override wins over the global SSH rewrite for that specific org. This is a workaround — prefer fixing at the tool level when possible, since a no-op insteadOf is easy to misread.
