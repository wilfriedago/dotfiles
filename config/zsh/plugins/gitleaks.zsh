# =============================================================================================
# ~/.config/zsh/plugins/gitleaks.zsh
# =============================================================================================
# Gitleaks Zsh Plugin
# This plugin provides aliases and completion for Gitleaks.
#
# It makes scanning code and git repositories for secrets directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Gitleaks is installed
if (( ! $+commands[gitleaks] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias gl='gitleaks'
alias glg='gitleaks git'
alias gld='gitleaks dir'
alias gls='gitleaks stdin'
alias glv='gitleaks version'
alias glp='gitleaks git --pre-commit --staged'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_gitleaks" ]]; then
  typeset -g -A _comps
  autoload -Uz _gitleaks
  _comps[gitleaks]=_gitleaks
  _comps[gl]=_gitleaks
  gitleaks completion zsh >| "$ZSH_CACHE_DIR/completions/_gitleaks" &|
fi
