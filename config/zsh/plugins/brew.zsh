# =============================================================================================
# ~/.config/zsh/plugins/brew.zsh
# =============================================================================================
# Brew Zsh Plugin
# This plugin provides aliases and completion for Homebrew.
#
# It makes managing Homebrew packages directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Brew is installed
if (( ! $+commands[brew] )); then
  return
fi

# Environment Variables
export HOMEBREW_NO_ANALYTICS=1 # Disable Homebrew analytics
export HOMEBREW_DEVELOPER=1 # Enable developer mode
export HOMEBREW_AUTO_UPDATE_SECS=604800 # 1 week
export HOMEBREW_NO_ENV_HINTS=1 # Disable Homebrew environment hints

# Aliases
alias binfo="brew info"
alias binstall="brew install"
alias buninstall="brew uninstall"
alias bsearch="brew search"
alias boutdated="brew outdated"
alias bupdate="brew update"
alias bupgrade="brew upgrade"
alias bclean="brew cleanup"
