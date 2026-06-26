# =============================================================================================
# ~/.config/zsh/plugins/tex.zsh
# =============================================================================================
# TeX / MacTeX Zsh Plugin
# This plugin ensures the MacTeX binaries are on the PATH and provides aliases.
#
# MacTeX installs its tools under /Library/TeX/texbin. macOS normally adds this
# via /etc/paths.d/TeX, but we add it here too so the PATH is explicit and
# portable across machines.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# =============================================================================================
# Environment variables
# =============================================================================================
case ":$PATH:" in
  *":/Library/TeX/texbin:"*) ;;
  *) export PATH="/Library/TeX/texbin:$PATH" ;;
esac

# Check if TeX is installed
if (( ! $+commands[tex] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias tlmgr-update='sudo tlmgr update --self --all'
