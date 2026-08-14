# =============================================================================================
# ~/.config/zsh/plugins/doctl.zsh
# =============================================================================================
# Digital Ocean CLI (doctl) Zsh Plugin
# This plugin provides aliases and completion for the Digital Ocean CLI (doctl).
#
# It allows you to manage Digital Ocean resources directly from the command line.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Digital Ocean CLI is installed
(( $+commands[doctl] )) || return

# Aliases
alias doc='doctl'
alias dodrop='doctl compute droplet'

# Completions
if [[ ! -s "$ZSH_CACHE_DIR/completions/_doctl" ]]; then
  typeset -g -A _comps
  autoload -Uz _doctl
  _comps[doctl]=_doctl
  doctl completion zsh >| "$ZSH_CACHE_DIR/completions/_doctl" &|
fi
