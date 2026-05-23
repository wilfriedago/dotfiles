# =============================================================================================
# ~/.config/zsh/plugins/direnv.zsh
# =============================================================================================
# direnv Zsh Plugin
# This plugin initializes direnv for automatic per-directory environment loading.
#
# Automatically loads/unloads .envrc files when entering/leaving directories.
# Replaces manual `loadenv` usage with seamless project switching.
# For docs and more info, see: https://direnv.net
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if direnv is installed
if (( ! $+commands[direnv] )); then
  return
fi

# =============================================================================================
# Initialization
# =============================================================================================
_cache_eval "direnv" "direnv hook zsh" "$(command -v direnv)"
