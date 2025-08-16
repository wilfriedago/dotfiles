# =============================================================================================
# ~/.config/zsh/plugins/yarn.zsh
# =============================================================================================
# Yarn Zsh Plugin
# This plugin provides aliases and completion for Yarn.
#
# Makes life easier when working with Yarn projects.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Yarn is installed
if (( ! $+commands[corepack] )); then
  return
fi

# Yarn Aliases
alias yarn='corepack yarn'
alias y='yarn'
alias ya='yarn add'
alias yar='yarn remove'
alias yau='yarn upgrade'
alias ypl='yarn plugin'
alias yst='yarn start'
alias yte='yarn test'
alias ybu='yarn build'
