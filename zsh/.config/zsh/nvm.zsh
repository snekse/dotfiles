# NVM — Node Version Manager — lazy loaded for shell startup performance
# Installed via install/nvm.sh (not Homebrew)
export NVM_DIR="$HOME/.nvm"

# Lazy loader: initializes NVM on first use of node/npm/npx/nvm
_nvm_load() {
  unset -f node npm npx nvm yarn pnpm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

# Placeholder functions that trigger lazy load
node()  { _nvm_load; node  "$@"; }
npm()   { _nvm_load; npm   "$@"; }
npx()   { _nvm_load; npx   "$@"; }
nvm()   { _nvm_load; nvm   "$@"; }
yarn()  { _nvm_load; yarn  "$@"; }
pnpm()  { _nvm_load; pnpm  "$@"; }

autoload -Uz add-zsh-hook

# Auto-use .nvmrc when entering a directory (without initializing NVM at startup)
# Reads .nvmrc directly rather than calling `nvm use`, keeping startup fast
_nvm_auto_use() {
  local nvmrc_path
  nvmrc_path="$(pwd)/.nvmrc"
  if [[ -f "$nvmrc_path" ]]; then
    local nvmrc_node_version
    nvmrc_node_version=$(cat "$nvmrc_path")
    echo "Found .nvmrc: $nvmrc_node_version (run 'nvm use' to activate)"
  fi
}
add-zsh-hook chpwd _nvm_auto_use
