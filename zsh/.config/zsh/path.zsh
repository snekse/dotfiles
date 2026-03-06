# Build PATH cleanly, only including directories that exist
typeset -U path  # auto-deduplicate

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$DOTFILES/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/.docker/bin"
  "/Applications/Obsidian.app/Contents/MacOS"
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
# Note: must be unquoted for glob qualifier (N-/) to work
path=(${^path}(N-/))
export PATH

# uv shell environment (managed by uv installer)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
