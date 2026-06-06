# =============================================================================================
# ~/.config/zsh/plugins/mole.zsh
# =============================================================================================
# Mole (mo) Zsh Plugin
# This plugin provides aliases and completion for Mole (mo), a Mac cleanup utility.
#
# It helps free up disk space, uninstall apps, optimize caches and monitor system health.
# For docs and more info, see: https://github.com/tw93/mole
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Mole is installed
if (( ! $+commands[mo] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias moc='mo clean'                # free up disk space
alias mocd='mo clean --dry-run'     # preview cleanup
alias moo='mo optimize'             # refresh caches and services
alias mood='mo optimize --dry-run'  # preview optimization
alias moa='mo analyze'              # explore disk usage
alias mos='mo status'               # monitor system health
alias moh='mo history'              # review cleanup activity
alias mop='mo purge'                # remove old project artifacts
alias mopd='mo purge --dry-run'     # preview project purge
alias mou='mo uninstall'            # remove apps completely

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_mole" ]]; then
  typeset -g -A _comps
  autoload -Uz _mole
  _comps[mole]=_mole
  _comps[mo]=_mole
  mo completion zsh >| "$ZSH_CACHE_DIR/completions/_mole" &|
fi
