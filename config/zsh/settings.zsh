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
