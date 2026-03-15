# =============================================================================
# Filesystem
# =============================================================================

# Create a directory and cd into it in one step
# Usage: mkcd my-new-project
mkcd() { mkdir -p "$1" && cd "$1"; }

# =============================================================================
# Network
# =============================================================================

# Show what process is listening on a given port
# Usage: whatIsOnPort 3001
# -n = no DNS resolution (faster), -P = no port name resolution, i4TCP = IPv4 TCP only
whatIsOnPort() {
  lsof -nP -i4TCP:"$1" | grep LISTEN
}

# Broader port lookup — shows all connections on a port, not just LISTEN
# Usage: port 3001
port() { lsof -i ":${1:?Usage: port <number>}"; }

# =============================================================================
# Git
# =============================================================================

# Clone a repo into a structured directory derived from the URL
# Parses host/owner/repo from SSH or HTTPS URLs; github.com maps to $GITHUB_DIR
# Optional second arg overrides the repo folder name
# Usage: gclone git@github.com:snekse/dotfiles.git
#        gclone git@github.com:nicknisi/dotfiles.git dotfiles-nick-nisi
gclone() {
  local url="${1:?Usage: gclone <repo-url> [alt-name]}"
  local alt_name="$2"
  local host owner repo

  if [[ "$url" =~ ^git@([^:]+):([^/]+)/(.+)$ ]]; then
    host="${match[1]}"
    owner="${match[2]}"
    repo="${match[3]%.git}"
  elif [[ "$url" =~ ^https?://([^/]+)/([^/]+)/(.+)$ ]]; then
    host="${match[1]}"
    owner="${match[2]}"
    repo="${match[3]%.git}"
  else
    echo "gclone: cannot parse URL: $url" >&2
    return 1
  fi

  local base
  case "$host" in
    github.com) base="${GITHUB_DIR:-${DEV:-$HOME/dev}/github}" ;;
    *)          base="${DEV:-$HOME/dev}/$host" ;;
  esac

  local dest="$base/$owner/${alt_name:-$repo}"
  mkdir -p "$base/$owner"
  git clone "$url" "$dest"

  read -rp "Would you like to go there now? [Y/n] " go
  [[ "${go:-y}" =~ ^[Yy]$ ]] && cd "$dest"
}

# =============================================================================
# GPG
# =============================================================================

# Create a new GPG key for git commit signing
# Usage: createGpgKey
createGpgKey() {
  bash "${DOTFILES_DIR:-$HOME/dotfiles}/install/configure_gpg.sh"
}

# Export a GPG public key in ASCII-armored format
# Usage: exportGpgPublicKey <key-id>
exportGpgPublicKey() {
  local key_id="${1:?Usage: exportGpgPublicKey <key-id>}"
  local output
  output=$(gpg --armor --export "$key_id")

  read -rp "Output to (c)lipboard or (d)isplay? [c/d, default: d] " dest
  if [[ "${dest:-d}" =~ ^[Cc]$ ]]; then
    echo "$output" | pbcopy
    echo "Public key copied to clipboard."
  else
    echo "$output"
  fi
}

# Export a GPG private key in ASCII-armored format
# PRIVACY: call with a leading space to suppress shell history:  exportGpgPrivateKey <key-id>
# Requires HIST_IGNORE_SPACE (already set in this dotfiles repo)
exportGpgPrivateKey() {
  local key_id="${1:?Usage: exportGpgPrivateKey <key-id>}"
  local output
  output=$(gpg --armor --export-secret-keys "$key_id")

  read -rp "Output to (c)lipboard or (d)isplay? [c/d, default: d] " dest
  if [[ "${dest:-d}" =~ ^[Cc]$ ]]; then
    echo "$output" | pbcopy
    echo "Private key copied to clipboard."
  else
    echo "$output"
  fi
}

# =============================================================================
# Local development
# =============================================================================

# Spin up a quick HTTP server in the current directory
# Useful for testing static sites or serving files locally
# Usage: serve        (defaults to port 8000)
#        serve 9000   (use a custom port)
serve() { python3 -m http.server "${1:-8000}"; }

# =============================================================================
# Docker Compose helpers
# =============================================================================

# Start all services in a docker compose file in detached mode
# Usage: dcUp
#        dcUp docker-compose.dev.yml
dcUp() {
  docker-compose -f "${1:-docker-compose.yml}" up -d
}

# Start a single service without recreating its dependencies
# Usage: dcUpJust mysql
#        dcUpJust docker-compose.dev.yml mysql
dcUpJust() {
  docker-compose -f "${1:-docker-compose.yml}" up -d --no-deps --build "$2"
}

# Pull updated images for all services in a docker compose file
# Usage: dcPull
#        dcPull docker-compose.dev.yml
dcPull() {
  docker-compose -f "${1:-docker-compose.yml}" pull
}

# Stop and remove all containers, networks, and volumes defined in a compose file
# Usage: dcDown
#        dcDown docker-compose.dev.yml
dcDown() {
  docker-compose -f "${1:-docker-compose.yml}" rm -s -v --force
}
