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

# =============================================================================================
# Environment variables
# =============================================================================================
export GOPATH="$HOME/.go"
case ":$PATH:" in
  *":$GOPATH/bin:"*) ;;
  *) export PATH="$GOPATH/bin:$PATH" ;;
esac

# Check if Go is installed
if (( ! $+commands[go] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias gofmt="go fmt"
