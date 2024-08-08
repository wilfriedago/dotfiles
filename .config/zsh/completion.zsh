# Load Angular CLI autocompletion.
source <(ng completion script)

# Load fabric completions.
if [ -f "$HOME/.config/fabric/fabric-bootstrap.inc" ]; then . "$HOME/.config/fabric/fabric-bootstrap.inc"; fi

# zstyle
zstyle ':completion:*' fzf-search-display true
