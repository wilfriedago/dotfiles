# =============================================================================================
# ~/.config/zsh/plugins/quarkus.zsh
# =============================================================================================
# Quarkus Zsh Plugin
# This plugin provides aliases and completion for Quarkus.
#
# It makes managing Quarkus projects directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Quarkus is installed
if (( ! $+commands[quarkus] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias q='quarkus'
