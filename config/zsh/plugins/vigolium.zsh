# =============================================================================================
# ~/.config/zsh/plugins/vigolium.zsh
# =============================================================================================
# Vigolium CLI Zsh Plugin
# This plugin ensures the Vigolium CLI is on the PATH and provides aliases.
#
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Environment Variables
# The CLI installs itself into $XDG_BIN_HOME. This runs before the guard so the
# binary becomes findable in the first place.
case ":$PATH:" in
  *":$XDG_BIN_HOME:"*) ;;
  *) export PATH="$XDG_BIN_HOME:$PATH" ;;
esac

# Guards
(( $+commands[vigolium] )) || return

# Aliases
alias vg='vigolium'
