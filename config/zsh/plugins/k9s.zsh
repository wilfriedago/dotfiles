# =============================================================================================
# ~/.config/zsh/plugins/k9s.zsh
# =============================================================================================
# K9s Zsh Plugin
# This plugin provides aliases and completion for K9s.
#
# It makes managing Kubernetes clusters directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if K9s is installed
if (( ! $+commands[k9s] )); then
  return
fi

# Completions
if [[ ! -f "$ZSH_CACHE_DIR/completions/_k9s" ]]; then
  typeset -g -A _comps
  autoload -Uz _k9s
  _comps[k9s]=_k9s
  k9s completion zsh >| "$ZSH_CACHE_DIR/completions/_k9s" &|
fi
