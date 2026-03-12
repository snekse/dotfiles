#!/usr/bin/env bash
# macOS system defaults
# Run with: just macos
# Safe to re-run. Requires logout/restart for some settings to take effect.

set -e

echo "==> Applying macOS defaults..."

# ============================================================
# General UI
# ============================================================

# Expand save panel by default
# Revert: defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
# Revert: defaults delete NSGlobalDomain PMPrintingExpandedStateForPrint
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Save to disk (not iCloud) by default
# Revert: defaults delete NSGlobalDomain NSDocumentSaveNewDocumentsToCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# ============================================================
# Finder
# ============================================================

# Show all filename extensions
# Revert: defaults delete NSGlobalDomain AppleShowAllExtensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files by default
# Revert: defaults write com.apple.finder AppleShowAllFiles -bool false
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show status bar
# Revert: defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
# Revert: defaults write com.apple.finder ShowPathbar -bool false
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
# Revert: defaults delete com.apple.finder _FXShowPosixPathInTitle
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
# Revert: defaults delete com.apple.finder _FXSortFoldersFirst
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search the current folder by default
# Revert: defaults delete com.apple.finder FXDefaultSearchScope
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Use list view by default
# Revert: defaults delete com.apple.finder FXPreferredViewStyle
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show ~/Library folder
# Revert: chflags hidden ~/Library
chflags nohidden ~/Library

# ============================================================
# Activity Monitor
# ============================================================

# Show all processes (not just My Processes)
# Revert: defaults delete com.apple.ActivityMonitor ShowCategory
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Visualize CPU usage in the Activity Monitor Dock icon
# Revert: defaults delete com.apple.ActivityMonitor IconType
defaults write com.apple.ActivityMonitor IconType -int 5

# ============================================================
# Dock
# ============================================================

# Remove stock apps that clutter the default Dock
# Wrapper suppresses exit code 1 when app is already absent
dock_remove() { dockutil --remove "$1" --no-restart 2>/dev/null || true; }

dock_remove "Phone"
dock_remove "FaceTime"
dock_remove "Photos"
dock_remove "Maps"
dock_remove "Mail"
dock_remove "Messages"
dock_remove "TV"
dock_remove "Music"
dock_remove "Keynote"
dock_remove "Numbers"
dock_remove "Pages"
dock_remove "Games"
dock_remove "iPhone Mirroring"

# ============================================================
# Apply changes
# ============================================================

echo "==> Restarting affected applications..."
for app in "Finder" "Dock" "SystemUIServer"; do
  killall "$app" &>/dev/null || true
done

echo ""
echo "==> Done. Some settings require a logout or restart to take effect."
