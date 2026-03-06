# =============================================================================
# Navigation
# =============================================================================

# eza is a modern replacement for ls (brew install eza)
# -l = long format, -a = include hidden files, -h = human-readable sizes
# --git = show git status column next to each file
alias ll='eza -lah --git'

# Plain eza with no flags — colorized ls replacement
alias l='eza'

# Go back to the previous directory (like browser back button)
alias b='cd -'

alias ..='cd ..'
alias ...='cd ../..'

# =============================================================================
# Git
# =============================================================================

# Short status — shows M (modified), A (added), ? (untracked), etc.
alias gs='git status -s'

alias ga='git add'

# Open commit message in $EDITOR with a full diff shown below the message
alias gc='git commit -v'

# Same as gc but stages all tracked modified files first (-a)
alias gca='git commit -v -a'

alias gco='git checkout'

# Pull and replay your local commits on top of the fetched changes
alias gl='git pull --rebase'

alias gp='git push'
alias gd='git diff'

# Compact decorated graph log — useful for visualizing branch history
alias glg="git log --decorate --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"

# =============================================================================
# Utilities
# =============================================================================

# Pretty-print JSON from stdin: echo '{"a":1}' | jsonify
# Requires jq (brew install jq)
alias jsonify='jq .'

# Print your public SSH key(s) to stdout — useful for copying to GitHub, servers, etc.
alias pubkey='cat ~/.ssh/*.pub'

# =============================================================================
# macOS Finder
# =============================================================================

# Toggle hidden files (files starting with .) visible in Finder
# Uses macOS defaults system to flip the AppleShowAllFiles setting,
# then restarts Finder to apply it
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'

# =============================================================================
# Gradle
# =============================================================================

# Run the project-local Gradle wrapper (not a globally installed gradle)
# The wrapper script is checked into each project at ./gradlew
alias gb="./gradlew build"

# =============================================================================
# Maven / Gradle — build artifact cleanup
# =============================================================================

# List all 'target' directories recursively from the current directory.
# These are build output dirs created by Maven/Gradle and can be safely deleted.
# To actually delete them, pipe to xargs: deleteTargetDirs | xargs rm -rf
alias deleteTargetDirs="find . -name target -type d"
