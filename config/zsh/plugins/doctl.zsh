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
if (( ! $+commands[doctl] )); then
  return
fi

# Aliases
alias doc='doctl'
alias docg='doctl compute droplet create'
alias docl='doctl compute droplet list'
alias docd='doctl compute droplet delete'
alias doci='doctl compute droplet get'
alias docp='doctl compute droplet power-on'
alias docf='doctl compute droplet shutdown'
alias docb='doctl compute droplet reboot'

# Completions
if [[ ! -f "$ZSH_CACHE_DIR/completions/_doctl" ]]; then
  typeset -g -A _comps
  autoload -Uz _doctl
  _comps[doctl]=_doctl
  doctl completion zsh >| "$ZSH_CACHE_DIR/completions/_doctl" &|
fi
