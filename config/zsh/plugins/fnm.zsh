# =============================================================================================
# ~/.config/zsh/plugins/fnm.zsh
# =============================================================================================
# FNM (Fast Node Manager) Zsh Plugin
# This plugin provides aliases and completion for FNM.
#
# It makes managing Node.js versions directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if FNM is installed
if (( ! $+commands[fnm] )); then
  return
fi

# =============================================================================================
# Initialization
# =============================================================================================
_cache_eval "fnm" "fnm env --use-on-cd --shell zsh" "$(command -v fnm)"
