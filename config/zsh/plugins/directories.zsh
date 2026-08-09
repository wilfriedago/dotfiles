# =============================================================================================
# ~/.config/zsh/plugins/directories.zsh
# =============================================================================================
# Zoxide Zsh Plugin
# This plugin provides aliases and completion for Zoxide.
#
# It makes directory navigation easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if zoxide is installed
(( $+commands[zoxide] )) || return

export _ZO_DOCTOR=0 # Disable zoxide doctor checks (optional, but can speed up startup)

# Initialization — cached for faster startup
_cache_eval "zoxide" "zoxide init --cmd ${ZOXIDE_CMD_OVERRIDE:-z} zsh" "$(command -v zoxide)"

# Settings
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# Aliases
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -- -='cd -'
alias cd='z'
alias 1='z -1'
alias 2='z -2'
alias 3='z -3'
alias 4='z -4'
alias 5='z -5'
alias 6='z -6'
alias 7='z -7'
alias 8='z -8'
alias 9='z -9'
alias l="eza -al --icons" # ls -l with icons
alias ll='eza -l --icons' # ls long format with icons
alias la='eza -a --icons' # ls all files with icons
alias ls='eza -a --icons --level=1' # ls with icons
alias lt="eza -al --icons --level=3 --tree --git-ignore" # ls tree with icons

# Functions
function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}

compdef _dirs d

# Wrap zoxide's z in a real function so `compdef`/completion has something to attach to.
# Originally added for fzf-tab; kept as a plain passthrough since zoxide's own `z` is
# defined via eval and replacing it here would change jump behaviour.
z () {
  \__zoxide_z "$@"
}
