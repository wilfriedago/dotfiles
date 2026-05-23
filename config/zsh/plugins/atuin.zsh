# =============================================================================================
# ~/.config/zsh/plugins/atuin.zsh
# =============================================================================================
# Atuin Zsh Plugin
# This plugin initializes Atuin, a SQLite-backed shell history replacement.
#
# Provides unlimited history, fuzzy search, per-directory filtering,
# duration/exit-code tracking, and optional cross-machine sync.
# For docs and more info, see: https://atuin.sh
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if atuin is installed
if (( ! $+commands[atuin] )); then
  return
fi

# =============================================================================================
# Initialization
# =============================================================================================
_cache_eval "atuin" "atuin init zsh --disable-up-arrow" "$(command -v atuin)"

# =============================================================================================
# Aliases
# =============================================================================================
alias hi='atuin search -i'       # interactive history search
alias his='atuin search'         # search history
alias hist='atuin stats'         # history statistics
