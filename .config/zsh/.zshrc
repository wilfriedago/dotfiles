########################################################################
# ~/.config/zsh/.zshrc                                                 #
########################################################################
# Instructions to be executed when a new ZSH session is launched       #
# Imports all plugins, aliases, helper functions, and configurations   #
#                                                                      #
# After editing, re-source .zshrc for new changes to take effect       #
# For docs and more info, see: https://github.com/wilfriedago/dotfiles #
#####################################################################  #
# Licensed under MIT (C) Alicia Sykes 2025 <https://wilfriedago.dev>   #
########################################################################

# Profiling
# zmodload zsh/zprof

# =============================================================================================
# ZSH Configuration
# =============================================================================================

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [[ ! -f $ZINIT_HOME/zinit.zsh ]]; then
  command mkdir -p "$(dirname "$ZINIT_HOME")" && command chmod g-rwX "$(dirname "$ZINIT_HOME")"
  command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Load zinit's completion system
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load starship theme
zinit ice as"command" from"gh-r" atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" atpull"%atclone" src"init.zsh"
zinit light starship/starship

# Plugins
zinit light-mode for \
  zsh-users/zsh-autosuggestions \
  zdharma-continuum/fast-syntax-highlighting \
  Aloxaf/fzf-tab

# History
HIST_STAMPS="yyyy-mm-dd"              # Set the format of the history timestamp
HIST_IGNORE_SPACE="true"              # Ignore commands that start with space
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000                        # Set the maximum number of history entries
SAVEHIST=10000                        # Set the maximum number of history entries to save in the file
setopt extended_history               # record timestamp of command in HISTFILE
setopt hist_expire_dups_first         # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups               # ignore duplicated commands history list
setopt hist_ignore_space              # ignore commands that start with space
setopt hist_verify                    # show command with history expansion to user before running it
setopt share_history                  # share command history data between sessions

# Initialize completion
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi

# =============================================================================================
# Shell
# =============================================================================================

[ -f "$XDG_CONFIG_HOME/zsh/aliases.zsh" ] && source "$XDG_CONFIG_HOME/zsh/aliases.zsh" # Aliases
[ -f "$XDG_CONFIG_HOME/zsh/functions.zsh" ] && source "$XDG_CONFIG_HOME/zsh/functions.zsh" # Functions
[ -f "$XDG_CONFIG_HOME/zsh/completions.zsh" ] && source "$XDG_CONFIG_HOME/zsh/completions.zsh" # Completions

# =============================================================================================
# Initialization
# =============================================================================================

# FNM
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(fnm completions --shell zsh)"

# ZOXIDE
eval "$(zoxide init --cmd ${ZOXIDE_CMD_OVERRIDE:-z} zsh)"

# FZF
eval "$(fzf --zsh)"
source "$HOME/.scripts/fzf/fzf-zsh-completion.sh"

# =============================================================================================
# Miscellaneous
# =============================================================================================

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# Clean up PATH
typeset -U PATH
clean_path

# Profiling
# zprof
