#!/usr/bin/env zsh

# Tab is consumed by IRIS at the PTY layer before zsh's ZLE ever sees it, so these
# styles only take effect in a rescue shell (IRIS_RESCUE=1) or if IRIS is disabled.
# They are kept working for exactly that case.

# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# native zsh menu selection — previously `no`, which existed only so fzf-tab could
# capture the unambiguous prefix. With fzf-tab gone that left Tab with no menu at all.
zstyle ':completion:*' menu select

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
zstyle ':completion:*:*:kill:*'             menu                yes select
zstyle ':completion:*:*:kill:*'             force-list          always
zstyle ':completion:*:*:kill:*'             insert-ids          single
