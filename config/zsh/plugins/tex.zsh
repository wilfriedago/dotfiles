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

# Environment variables
export TEXBIN_DIR="/Library/TeX/texbin"

# Add TeX binaries to PATH if not already present
case ":$PATH:" in
  *":$TEXBIN_DIR:"*) ;;
  *) export PATH="$TEXBIN_DIR:$PATH" ;;
esac

# Aliases
alias tlmgr-update='sudo tlmgr update --self --all'
