# ~/.zshrc — loaded for interactive shells

# XDG base dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

DOTFILES="$HOME/dotfiles"
ZSH_CONFIG="$XDG_CONFIG_HOME/zsh"

# Source all zsh config modules
for config in "$ZSH_CONFIG"/*.zsh; do
  source "$config"
done

# Machine-local overrides (not in repo)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Prompt
eval "$(starship init zsh)"

# Added by Antigravity
export PATH="$PATH:$HOME/.antigravity/antigravity/bin"

# pnpm
export PNPM_HOME="/Users/derek/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/derek/.lmstudio/bin"
# End of LM Studio CLI section

# Added by Claude Code CLI
export PATH="$HOME/.local/bin:$PATH"

# Added by Antigravity IDE
export PATH="$PATH:$HOME/.antigravity-ide/antigravity-ide/bin"
