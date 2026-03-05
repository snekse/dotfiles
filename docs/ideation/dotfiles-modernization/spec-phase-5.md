# Spec: Phase 5 — macOS Defaults

## Overview

Create `macos/defaults.sh` — a script that applies macOS system preferences via `defaults write`. Based on best practices from mathiasbynens/dotfiles and the Daytona.io Ultimate Dotfiles Guide, reviewed against your actual preferences.

This script is **idempotent** (safe to run multiple times) and **non-destructive by default** (everything can be reverted). It is run explicitly via `just macos`, never automatically during `just install`.

## Prerequisite

Phase 1 complete. No dependency on Phases 2-4.

---

## File Changes

### New files

```
~/dotfiles/
  macos/
    defaults.sh
```

Note: `macos/` is NOT a Stow package — it contains scripts, not dotfiles. It does not get `stow`'d.

---

## Implementation Details

### Interactive Review Process

Before writing `defaults.sh`, run a Claude Code session that:

1. Reads the user's current machine settings to discover existing customizations: `defaults read com.apple.finder`, `defaults read com.apple.dock`, etc.
2. Presents sections of defaults settings (Finder, Dock, keyboard, screenshots, etc.)
3. For each section, shows the current machine value vs. the proposed setting
4. Asks which settings to include

### `macos/defaults.sh` — Structure

```bash
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
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# ============================================================
# Keyboard & Input
# ============================================================

# Enable full keyboard access for all controls (Tab moves focus to all UI elements)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# ============================================================
# Finder
# ============================================================

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use list view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show ~/Library folder
chflags nohidden ~/Library

# ============================================================
# Dock
# ============================================================

# Set Dock icon size
defaults write com.apple.dock tilesize -int 48

# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Remove delay for Dock auto-hide
defaults write com.apple.dock autohide-delay -float 0

# ============================================================
# Screenshots
# ============================================================

# Save screenshots to Downloads (avoids Desktop clutter)
defaults write com.apple.screencapture location -string "$HOME/Downloads"

# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"

# Disable screenshot shadow
defaults write com.apple.screencapture disable-shadow -bool true

# ============================================================
# Safari & WebKit
# ============================================================

# Enable the Develop menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# ============================================================
# Terminal & Shell
# ============================================================

# Only use UTF-8 in Terminal
defaults write com.apple.terminal StringEncodings -array 4

# ============================================================
# Activity Monitor
# ============================================================

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Visualize CPU usage in the Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# ============================================================
# Apply changes
# ============================================================

echo "==> Restarting affected applications..."
for app in "Finder" "Dock" "SystemUIServer" "Safari"; do
  killall "$app" &>/dev/null || true
done

echo ""
echo "==> Done. Some settings require a logout or restart to take effect."
```

### Add to Justfile

```justfile
# Apply macOS system defaults (run explicitly, not part of just install)
macos:
    bash macos/defaults.sh
```

**Important:** Do NOT add `macos` to the `install` target. macOS defaults should be applied deliberately, not automatically on every `just install`. This is especially important on client machines where you may not want to apply personal macOS preferences.

---

## Settings to Review During Interactive Session

Present these as options during the config review session. Some people have strong preferences either way:

| Setting | Default in script | Review? |
|---|---|---|
| Auto-hide Dock | Yes | Yes — some people hate this |
| Screenshot location | `~/Downloads` | Yes — `~/Desktop` is common too |
| Show hidden files | Yes | Probably yes for a developer |
| Key repeat rate | Fast (2/15) | Yes — very personal preference |
| Disable autocorrect | Yes | Yes — annoying for code but useful for prose |
| Full keyboard access | Yes | Probably yes |

---

## Reverting Settings

If a setting causes issues, revert with:

```bash
# Example: re-enable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool true

# Or delete the key to restore system default
defaults delete NSGlobalDomain NSAutomaticSpellingCorrectionEnabled
```

Document the revert commands inline in `defaults.sh` as comments next to each setting.

---

## Validation

```bash
# Dry run — check what current values are before applying
defaults read NSGlobalDomain ApplePressAndHoldEnabled
defaults read com.apple.finder AppleShowAllFiles
defaults read com.apple.dock autohide

# Apply
just macos

# Verify key settings took effect
defaults read NSGlobalDomain KeyRepeat          # should be 2
defaults read com.apple.dock autohide           # should be 1 (true)
defaults read com.apple.screencapture location  # should be ~/Downloads
```

## Feedback Loop

**Inner-loop command:** `defaults read <domain> <key>` — verify a specific setting after applying.

This phase has no iterative feedback loop in the traditional sense — it's a one-shot apply. The interactive review session (deciding which settings to include) is the main work. After applying, visual verification of the Dock, Finder, and keyboard behavior is the real test.
