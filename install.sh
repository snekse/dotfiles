#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"

echo "==> Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon path fix
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

echo "==> Installing just..."
brew install just

echo "==> Running just install..."
cd "$DOTFILES" && just install
