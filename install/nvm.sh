#!/usr/bin/env bash
set -e

NVM_DIR="$HOME/.nvm"
NVM_SCRIPT="$NVM_DIR/nvm.sh"

if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_SCRIPT" ]]; then
  echo "==> NVM already installed, skipping installer"
else
  echo "==> Installing NVM..."
  # Install latest NVM (check https://github.com/nvm-sh/nvm/releases for current version)
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | METHOD=script bash
fi

source "$NVM_SCRIPT"

echo "==> Installing Node LTS..."
nvm install --lts
nvm use --lts
nvm alias default lts/*
