#!/usr/bin/env zsh

bindkey '^I' fzf_completion

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
zstyle ':completion:*' list-colors         ${(s.:.)LS_COLORS}  # Enable $LS_COLORS for directories in completion menu.
zstyle ':completion:*' special-dirs        yes                 # Enable completion menu of ./ and ../ special directories.

# Configure completion of 'kill' command.
zstyle ':completion:*:*:*:*:processes'      command             'ps -u $USER -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes'   list-colors         '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*'             menu                yes select
zstyle ':completion:*:*:kill:*'             force-list          always
zstyle ':completion:*:*:kill:*'             insert-ids          single

# TERRAFORM
if command -v terraform &> /dev/null; then
  complete -C "$(command -v terraform)" terraform
fi
