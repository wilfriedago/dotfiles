# =============================================================================================
# ~/.config/zsh/plugins/node.zsh
# =============================================================================================
# Node.js & NPM Zsh Plugin
# This plugin provides aliases and completion for Node.js and NPM.
#
# It makes managing Node.js packages directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Node.js is installed
if (( ! $+commands[node] )); then
  return
fi

# =============================================================================================
# Aliases - Node.js
# =============================================================================================
alias nd='node'

# =============================================================================================
# Aliases - NPM
# =============================================================================================
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nun='npm uninstall'
alias nup='npm update'
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
alias nrs='npm run start'
alias nrl='npm run lint'
alias ns='npm start'
alias nt='npm test'
alias nit='npm init'
alias niy='npm init -y'
alias no='npm outdated'
alias nls='npm list'
alias nlsg='npm list -g --depth=0'
alias nau='npm audit'
alias nauf='npm audit fix'
alias ncl='npm cache clean --force'
alias npub='npm publish'
alias nv='npm version'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_npm" ]]; then
  typeset -g -A _comps
  autoload -Uz _npm
  _comps[npm]=_npm
  npm completion >| "$ZSH_CACHE_DIR/completions/_npm" &|
fi
