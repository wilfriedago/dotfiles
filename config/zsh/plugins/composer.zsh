# =============================================================================================
# ~/.config/zsh/plugins/composer.zsh
# =============================================================================================
# Composer Zsh Plugin
# This plugin provides aliases and completion for Composer.
#
# It makes managing Composer commands directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Composer is installed
if (( ! $+commands[composer] )); then
  return
fi

# Environment variables
export COMPOSER_HOME="$XDG_CONFIG_HOME/composer"
export PATH="$COMPOSER_HOME/vendor/bin:$PATH"
