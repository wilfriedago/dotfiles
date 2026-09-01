#!/usr/bin/env bash

set -euo pipefail

# This file contains settings for mac which makes me happy.
# It is not a full list.
#
# The best resource of finding new settings for other users is:
# https://www.defaults-write.com
#
# Some parts are taken from:
# - https://github.com/rootbeersoup/dotfiles
# - https://github.com/skwp/dotfiles
#
# All values are sorted inside their blocks: newest are on the top.
#

echo 'Configuring your mac. Hang tight.'
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo 'This script only supports macOS.' >&2
  exit 1
fi

osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true


# === General ===

# Show battery percentage.
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

# Disable press-and-hold in favor of key repeat.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Scrollbars visible when scrolling:
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# Always use expanded save dialog:
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# This line deactivates rubber scrolling:
# http://osxdaily.com/2012/05/10/disable-elastic-rubber-band-scrolling-in-mac-os-x/
defaults write -g NSScrollViewRubberbanding -int 0

# Maximize windows on double clicking them:
defaults write -g AppleActionOnDoubleClick 'Maximize'

# Disable multitouch swipes:
defaults write -g AppleEnableSwipeNavigateWithScrolls -int 0

# Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0


# === Dock ===

# Size:
defaults write com.apple.dock tilesize -int 56

# Show indicator lights for open apps in Dock:
defaults write com.apple.dock show-process-indicators -bool true

# Lock the Dock size. Domain names are case-sensitive: the old `com.apple.Dock`
# spelling wrote to a plist nothing reads.
defaults write com.apple.dock size-immutable -bool true

# Show Dock instantly:
defaults write com.apple.dock autohide-delay -float 0

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true


# === Menu bar ===

# Make status icons smaller, so they will take less space:
# https://flaky.build/built-in-workaround-for-applications-hiding-under-the-macbook-pro-notch
defaults write -globalDomain NSStatusItemSelectionPadding -int 12
defaults write -globalDomain NSStatusItemSpacing -int 12


# === Finder ===

# Keep folders on top when sorting by name:
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Show Finder path bar:
defaults write com.apple.finder ShowPathbar -bool true

# Do not show status bar in Finder:
defaults write com.apple.finder ShowStatusBar -bool false

# Show hidden files in Finder:
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions in Finder:
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Allow quitting Finder via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Show Library folder
chflags nohidden ~/Library


# === Text editing ===

# Disable smart quotes:
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable autocorrect:
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-capitalization:
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes:
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution:
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false


# === Screenshots ===

# Keep screenshots out of the Desktop, and drop the window drop-shadow.
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture show-thumbnail -bool false


# === Trackpad ===

# Tap to click, for this host and for the login screen.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Full-speed pointer movement (no acceleration ceiling).
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3.0


# === Time Machine ===

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true


# === Activity monitor ===

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# === Touch ID for sudo ===

# /etc/pam.d/sudo_local survives OS updates; editing /etc/pam.d/sudo does not.
# Needs sudo, so it is skipped rather than failing the whole run.
if [[ ! -f /etc/pam.d/sudo_local ]]; then
  if sudo -n true 2>/dev/null; then
    printf 'auth       sufficient     pam_tid.so\n' | sudo tee /etc/pam.d/sudo_local >/dev/null
    echo 'Enabled Touch ID for sudo.'
  else
    echo 'Skipped Touch ID for sudo (needs sudo). To enable:'
    echo "  echo 'auth       sufficient     pam_tid.so' | sudo tee /etc/pam.d/sudo_local"
  fi
fi


# Restarting apps:
echo 'Restarting apps...'
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo 'Done! Some settings need a logout to take effect.'
