#!/usr/bin/env zsh

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'

# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

# hide parents
zstyle ':completion:*' ignored-patterns '.|..|.DS_Store|**/.|**/..|**/.DS_Store|**/.git'

# hide `..` and `.` from file menu
zstyle ':completion:*' ignore-parents 'parent pwd directory'

# show all files in the file menu
zstyle ':completion:*' fzf-search-display true

# Configure completion of directories.
zstyle ':completion:*'              list-colors         ${(s.:.)LS_COLORS}  # Enable $LS_COLORS for directories in completion menu.
zstyle ':completion:*'              special-dirs        yes                 # Enable completion menu of ./ and ../ special directories.

# Configure completion of 'kill' command.
zstyle ':completion:*:*:*:*:processes'      command             'ps -u $USER -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes'   list-colors         '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*'             menu                yes select
zstyle ':completion:*:*:kill:*'             force-list          always
zstyle ':completion:*:*:kill:*'             insert-ids          single

# Configure completion of 'man' command.
zstyle ':completion:*:man:*'                menu                yes select
zstyle ':completion:*:manuals'              separate-sections   yes
zstyle ':completion:*:manuals.*'            insert-sections     yes

# Initialize and optimize completion
autoload -Uz compinit

# Enable extended globbing.
setopt extendedglob

# Location for completions
zcompdump="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/.zcompdump"

# If completions present, then load them
if [ -f $zcompdump ]; then
  compinit -d $zcompdump
fi

# Perform compinit only once a day.
if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
  zcompile "$zcompdump"
fi

# Disable extended globbing so that ^ will behave as normal.
unsetopt extendedglob

# Load completions from Homebrew
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# Load completions from XDG_CONFIG_HOME
FPATH="${ZSH_COMPLETIONS_DIR}:${FPATH}"

# AWS
if command -v aws_completer &> /dev/null; then
  complete -C aws_completer aws
fi

# TERRAFORM
if command -v terraform &> /dev/null; then
  complete -C "$(command -v terraform)" terraform
fi

# ARTISAN
[[ -s "$PWD/artisan" && -x "$PWD/artisan" ]] && eval "$(php artisan completion zsh)"
