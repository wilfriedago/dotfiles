# =============================================================================================
# ~/.config/zsh/plugins/ngrok.zsh
# =============================================================================================
# Ngrok Zsh Plugin
# This plugin provides aliases and completion for Ngrok.
#
# It makes managing Ngrok tunnels directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Ngrok is installed
if (( ! $+commands[ngrok] )); then
  return
fi

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_ngrok" ]]; then
  typeset -g -A _comps
  autoload -Uz _ngrok
  _comps[ngrok]=_ngrok
  ngrok completion zsh >| "$ZSH_CACHE_DIR/completions/_ngrok" &|
fi
