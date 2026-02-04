# =============================================================================================
# ~/.config/zsh/plugins/pnpm.zsh
# =============================================================================================
# PNPM Zsh Plugin
# This plugin provides aliases and completion for PNPM.
#
# It makes managing Node.js packages directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if PNPM is installed
if (( ! $+commands[pnpm] )); then
  return
fi

# =============================================================================================
# Environment variables
# =============================================================================================
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# =============================================================================================
# Aliases
# =============================================================================================
alias pn='pnpm'
alias pi='pnpm install'
alias pd='pnpm dev'
alias pt='pnpm test'
alias pb='pnpm build'
alias pu='pnpm update'
alias po='pnpm outdated'
alias px='pnpm exec'
alias pr='pnpm run'
alias pdx='pnpm dlx'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_pnpm" ]]; then
  typeset -g -A _comps
  autoload -Uz _pnpm
  _comps[pnpm]=_pnpm
  _comps[pn]=_pnpm
  pnpm completion zsh >| "$ZSH_CACHE_DIR/completions/_pnpm" &|
fi
