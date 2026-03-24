# =============================================================================================
# ~/.config/zsh/plugins/python.zsh
# =============================================================================================
# Python Zsh Plugin
# This plugin provides aliases and completion for Python.
#
# It makes managing Python environments and packages directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Python is installed
if (( ! $+commands[python3] )); then
  return
fi

export PATH="$(brew --prefix python@3.11)/libexec/bin:$PATH"

# =============================================================================================
# Aliases
# =============================================================================================
alias python='python3'
alias pip='pip3'
alias py='python3'
alias pir='pip install -r requirements.txt'

