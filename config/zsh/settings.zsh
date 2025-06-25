# =============================================================================================
# Directory settings
# =============================================================================================

# Changing/making/removing directory
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus


alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias -- -='cd -'
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

function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}
compdef _dirs d

# =============================================================================================
# History settings
# =============================================================================================

## History file configuration
HISTFILE="${ZSH_CACHE_DIR}/.zhistory" # Set the history file location
HIST_STAMPS="yyyy-mm-dd"              # Set the format of the history timestamp
HISTSIZE=50000                        # Set the maximum number of history entries
SAVEHIST=10000                        # Set the maximum number of history entries to save in the file

# History command configuration.
setopt extended_history       # Record timestamp of command in $HISTFILE.
setopt hist_expire_dups_first # Delete duplicates first when $HISTFILE size exceeds $HISTSIZE.
setopt hist_ignore_dups       # Ignore duplicated commands in history list.
setopt hist_ignore_space      # Ignore commands that start with a space.
setopt hist_verify            # Show command with history expansion to user before running it.
setopt share_history          # Share history between different instances of the shell.
setopt hist_save_no_dups      # Do not save duplicates in history file.
setopt hist_find_no_dups      # Ignore duplicates when searching in history.
setopt hist_reduce_blanks     # Remove superfluous blanks from history items.

alias hi='history'
alias hil='history | less'
alias his='history | grep'
alias hisi='history | grep -i'

# =============================================================================================
# Completion settings
# =============================================================================================

COMPDUMP="${ZSH_CACHE_DIR}/.zcompdump" # Set the location for the completion dump file
if [[ -f $COMPDUMP ]]; then
  compinit -d $COMPDUMP # Load the completion dump file if it exists
fi

# Perform compinit only once a day.
if [[ -s "$COMPDUMP" && (! -s "${COMPDUMP}.zwc" || "$COMPDUMP" -nt "${COMPDUMP}.zwc") ]]; then
  zcompile "$COMPDUMP" # Compile the completion dump file if it is not already compiled
fi
