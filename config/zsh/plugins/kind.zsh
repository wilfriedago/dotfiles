# =============================================================================================
# ~/.config/zsh/plugins/kind.zsh
# =============================================================================================
# Kind Zsh Plugin
# This plugin provides aliases and completion for Kind.
#
# It makes managing Kubernetes clusters directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Kind is installed
if (( ! $+commands[kind] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias kd='kind'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_kind" ]]; then
  typeset -g -A _comps
  autoload -Uz _kind
  _comps[kind]=_kind
  kind completion zsh >| "$ZSH_CACHE_DIR/completions/_kind" &|
fi
