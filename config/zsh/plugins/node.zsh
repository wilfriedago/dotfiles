# =============================================================================================
# ~/.config/zsh/plugins/node.zsh
# =============================================================================================
# Node.js & NPM Zsh Plugin
# This plugin provides aliases and completion for Node.js and NPM.
#
# It makes managing Node.js packages directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Node.js is installed
if (( ! $+commands[node] )); then
  return
fi

# =============================================================================================
# Aliases - Node.js
# =============================================================================================
alias nd='node'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_npm" ]]; then
  typeset -g -A _comps
  autoload -Uz _npm
  _comps[npm]=_npm
  npm completion >| "$ZSH_CACHE_DIR/completions/_npm" &|
fi
