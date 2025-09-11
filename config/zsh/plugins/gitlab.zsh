# =============================================================================================
# ~/.config/zsh/plugins/gitlab.zsh
# =============================================================================================
# GitLab Zsh Plugin
# This plugin provides aliases and completion for GitLab.
#
# It makes managing GitLab projects directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if GitLab CLI is installed
if (( !$+commands[glab] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias gl='glab'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_glab" ]]; then
  typeset -g -A _comps
  autoload -Uz _glab
  _comps[glab]=_glab
  _comps[gl]=_glab
  glab completion -s zsh >| "$ZSH_CACHE_DIR/completions/_glab" &|
fi
