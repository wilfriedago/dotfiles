# =============================================================================================
# ~/.config/zsh/plugins/go.zsh
# =============================================================================================
# Go Zsh Plugin
# This plugin provides aliases and completion for Go.
#
# It makes managing Go environments and packages directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Environment Variables
export GO_HOME="$HOME/.go"
export GO_BIN="$GO_HOME/bin"

case ":$PATH:" in
  *":$GO_BIN:"*) ;;
  *) export PATH="$GO_BIN:$PATH" ;;
esac

# Guards
if (( ! $+commands[go] )); then
  return
fi
