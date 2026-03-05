# List available targets
default:
    @just --list

# Full install: link dotfiles and install packages
install: brew-install link

# Stow all packages
link:
    stow zsh git starship

# Unstow all packages
unlink:
    stow -D zsh git starship

# Install core CLI tools
brew-install:
    brew bundle --file=Brewfile

# Install optional GUI apps and App Store apps (not run by default)
install-apps:
    brew bundle --file=Brewfile.optional

# Upgrade everything
update:
    brew update && brew upgrade
    brew bundle --cleanup --file=Brewfile

# Check what brew bundle would change
brew-check:
    brew bundle check --file=Brewfile
    brew bundle check --file=Brewfile.optional
