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
