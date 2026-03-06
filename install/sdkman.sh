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

# Install Amazon Corretto LTS (latest available)
echo "==> Installing Amazon Corretto (Java LTS)..."
JAVA_VERSION=$(SDKMAN_COLOUR=false sdk list java 2>/dev/null \
  | grep -E '\bamzn\b' \
  | grep 'LTS' \
  | head -1 \
  | awk '{print $NF}')
sdk install java "$JAVA_VERSION"
sdk default java "$JAVA_VERSION"

# Install additional candidates as needed
# sdk install gradle
# sdk install maven
# Uncomment or add versions based on your projects
