export TERM="xterm-256color"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# History
export HISTSIZE=1000000
export HISTFILESIZE=1000000
export HISTFILE="$HOME/.zsh_history"
export HISTIGNORE="clear:bg:fg:cd:cd -:exit:date:w:* --help"
export HISTCONTROL=ignorespace
setopt HIST_IGNORE_SPACE

# Dev directories
export GITHUB_DIR="${DEV:-$HOME/dev}/github"

# Homebrew — auto-update at most once a week (default is 300s / 5 minutes)
export HOMEBREW_AUTO_UPDATE_SECS=604800

# Color
export CLICOLOR=1
export GREP_COLOR='1;32'
