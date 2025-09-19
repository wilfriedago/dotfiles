# =============================================================================================
# ~/.config/zsh/plugins/rovo.zsh
# =============================================================================================
# Rovo Zsh Plugin
# This plugin provides aliases and completion for Rovo.
#
# It makes working with Rovo directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Rovo is installed
if (( ! $+commands[acli] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias rovo='acli'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_acli" ]]; then
  typeset -g -A _comps
  autoload -Uz _acli
  _comps[acli]=_acli
  _comps[rovo]=_acli
  acli completion zsh >| "$ZSH_CACHE_DIR/completions/_acli" &|
fi
