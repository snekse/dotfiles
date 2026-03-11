#!/usr/bin/env bash
set -e

NVM_DIR="$HOME/.nvm"

if [[ -d "$NVM_DIR" ]]; then
  echo "==> NVM already installed, skipping installer"
else
  echo "==> Installing NVM..."
  # Install latest NVM (check https://github.com/nvm-sh/nvm/releases for current version)
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | METHOD=script bash
fi

source "$NVM_DIR/nvm.sh"

echo "==> Installing Node LTS..."
nvm install --lts
nvm use --lts
nvm alias default lts/*
