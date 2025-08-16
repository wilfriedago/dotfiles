# =============================================================================================
# ~/.config/zsh/plugins/bws.zsh
# =============================================================================================
# Bitwarden Secret Manager Zsh Plugin
# This plugin provides aliases and completion for Bitwarden Secret Manager.
#
# It makes managing Bitwarden Secret Manager commands directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Bitwarden Secret Manager is installed
if (( ! $+commands[bws] )); then
  return
fi

# Completions
if [[ ! -f "$ZSH_CACHE_DIR/completions/_bws" ]]; then
  typeset -g -A _comps
  autoload -Uz _bws
  _comps[bws]=_bws
  bws completions zsh >| "$ZSH_CACHE_DIR/completions/_bws" &|
fi
