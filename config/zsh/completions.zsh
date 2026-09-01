#!/usr/bin/env zsh

# Styles for zsh's completion system. fzf-tab renders the menu from these — see
# plugins/fzf.zsh for its own styles, and plugins/carapace.zsh for extra specs.

# Cache slow completions (brew, kubectl, docker, ...) under $ZSH_CACHE_DIR.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR}/completions"

# Case-insensitive, then partial-word, then substring matching.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' group-name ''

# No native menu: fzf-tab draws the menu instead and cannot intercept `menu select`.
zstyle ':completion:*' menu no

# hide parents
zstyle ':completion:*' ignored-patterns '.|..|.DS_Store|**/.|**/..|**/.DS_Store|**/.git'

# hide `..` and `.` from file menu
zstyle ':completion:*' ignore-parents 'parent pwd directory'

# Configure completion of directories.
zstyle ':completion:*' list-colors         ${(s.:.)LS_COLORS}  # Enable $LS_COLORS for directories in completion menu.
zstyle ':completion:*' special-dirs        yes                 # Enable completion menu of ./ and ../ special directories.

# Configure completion of 'kill' command.
zstyle ':completion:*:*:*:*:processes'      command             'ps -u $USER -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes'   list-colors         '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*'             menu                no
zstyle ':completion:*:*:kill:*'             force-list          always
zstyle ':completion:*:*:kill:*'             insert-ids          single
