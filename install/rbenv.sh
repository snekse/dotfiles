#!/usr/bin/env bash
set -e

if ! command -v rbenv &>/dev/null; then
  echo "==> rbenv not found — run brew bundle first"
  exit 1
fi

echo "==> Installing Ruby (latest stable)..."
RUBY_VERSION=$(rbenv install --list | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
rbenv install --skip-existing "$RUBY_VERSION"
rbenv global "$RUBY_VERSION"
