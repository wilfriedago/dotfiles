# =============================================================================================
# ~/.config/zsh/plugins/helm.zsh
# =============================================================================================
# Helm Zsh Plugin
# This plugin provides aliases and completion for Helm.
#
# It makes managing Helm charts directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Helm is installed
if (( ! $+commands[helm] )); then
  return
fi

# Completions
if [[ ! -s "$ZSH_CACHE_DIR/completions/_helm" ]]; then
  typeset -g -A _comps
  autoload -Uz _helm
  _comps[helm]=_helm
  _comps[h]=_helm
  helm completion zsh >| "$ZSH_CACHE_DIR/completions/_helm" &|
fi
