#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"
echo "Ensuring we're in the $DOTFILES directory..."
cd "$DOTFILES" 

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
brew install just --quiet

echo "==> Installing brew packages..."
just brew-install

echo "==> Linking dotfiles (stow)..."
just link

echo "==> Setting up SSH..."
bash install/configure_ssh.sh

echo "==> Installing language runtimes..."
just install-runtimes

# Finished
echo "==> Installation complete!"
