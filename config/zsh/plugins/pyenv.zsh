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

# =============================================================================================
# Environment variables
# =============================================================================================
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Check if pyenv is installed
if (( ! $+commands[pyenv] )); then
  return
fi

# =============================================================================================
# Initialization
# =============================================================================================
_cache_eval "pyenv" "pyenv init - zsh" "$(command -v pyenv)"
