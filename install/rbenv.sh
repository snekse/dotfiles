#!/usr/bin/env bash
set -e

if ! command -v rbenv &>/dev/null; then
  echo "==> rbenv not found — run brew bundle first"
  exit 1
fi

echo "==> Installing Ruby (latest stable)..."
RUBY_VERSION=$(rbenv install --list | awk '/^[0-9]+\.[0-9]+\.[0-9]+$/ { last = $1 } END { print last }')

if [[ -z "$RUBY_VERSION" ]]; then
  echo "==> Failed to determine latest Ruby version"
  exit 1
fi

rbenv install --skip-existing "$RUBY_VERSION"
rbenv global "$RUBY_VERSION"
