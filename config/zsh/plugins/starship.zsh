# =============================================================================================
# ~/.config/zsh/plugins/starship.zsh
# =============================================================================================
# Starship prompt
#
# The binary is installed by Homebrew (see Brewfile), not by Zinit — one source of truth per
# executable. Its `_starship` completion ships in /opt/homebrew/share/zsh/site-functions,
# which zshenv already puts on $fpath, so nothing is generated here.
#
# $STARSHIP_CONFIG and $STARSHIP_CACHE are exported in zshenv.
# For docs and more info, see: https://starship.rs
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Guards
(( $+commands[starship] )) || return

# Initialization — cached for faster startup
_cache_eval "starship" "starship init zsh" "$commands[starship]"
