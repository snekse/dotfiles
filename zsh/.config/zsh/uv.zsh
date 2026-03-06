# uv — Python package and project manager (replaces pyenv + pipenv + pip)
# Installed via Homebrew; manages Python versions, virtualenvs, and dependencies.
# https://docs.astral.sh/uv/

# Prefer uv-managed Python versions over system Python
export UV_PYTHON_PREFERENCE=managed

# Shell completions
eval "$(uv generate-shell-completion zsh)"
