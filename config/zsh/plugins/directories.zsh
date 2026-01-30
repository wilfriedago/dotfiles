
# Check if zoxide is installed
if (( ! $+commands[zoxide] )); then
  return
fi

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
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias md='mkdir -p'
alias rd=rmdir

# Functions
function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}
compdef _dirs d

# Override z to enable fzf-tab completion with `z name<tab>`
z () {
  \__zoxide_z "$@"
}
