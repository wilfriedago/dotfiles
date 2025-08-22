# =============================================================================================
# ~/.config/zsh/plugins/pyenv.zsh
# =============================================================================================
# PYENV Zsh Plugin
# This plugin provides aliases and completion for PYENV.
#
# It makes managing Python versions directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if pyenv is installed
if (( ! $+commands[pyenv] )); then
  return
fi

# Environment variables
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv
eval "$(pyenv init - zsh)"
