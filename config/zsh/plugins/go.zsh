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

# Check if Go is installed
if (( ! $+commands[go] )); then
  return
fi

# =============================================================================================
# Variables
# =============================================================================================
export GOROOT="/usr/local/go"
export GOPATH="$HOME/.go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# =============================================================================================
# Aliases
# =============================================================================================
alias gofmt="go fmt"
