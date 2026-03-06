# ~/.zshenv — loaded for ALL zsh sessions (login, interactive, scripts)
# Keep this minimal. Only things that must be available everywhere.

export EDITOR="$(command -v vim || command -v nano)"
export VISUAL="$EDITOR"
export DOTFILES="$HOME/dotfiles"
