# =============================================================================================
# ~/.config/zsh/plugins/angular.zsh
# =============================================================================================
# Angular CLI Zsh Plugin
# This plugin provides aliases and completion for Angular CLI.
#
# It makes managing Angular projects directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Angular CLI is installed
if (( ! $+commands[ng] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================

# Core commands
alias ngs='ng serve'
alias ngb='ng build'
alias ngt='ng test'
alias nge2e='ng e2e'
alias ngl='ng lint'

# Generation commands
alias ngg='ng generate'
alias nggc='ng generate component'
alias nggs='ng generate service'
alias nggd='ng generate directive'
alias nggp='ng generate pipe'
alias nggm='ng generate module'
alias nggg='ng generate guard'
alias nggi='ng generate interceptor'
alias nggr='ng generate resolver'

# Project setup
alias ngn='ng new'
alias nga='ng add'
alias ngu='ng update'

# Build commands
alias ngbp='ng build --prod'
alias ngbs='ng build --source-map'
alias ngbw='ng build --watch'

# Serve commands
alias ngso='ng serve --open'
alias ngsho='ng serve --host 0.0.0.0 --open'
alias ngsp='ng serve --prod'

# Test commands
alias ngth='ng test --no-watch --no-progress --browsers=ChromeHeadless'
alias ngtw='ng test --watch'
alias ngtc='ng test --code-coverage'

# Analytics
alias ngconfig='ng config'
alias ngversion='ng version'
alias nghelp='ng help'

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_ng" ]]; then
  typeset -g -A _comps
  autoload -Uz _ng
  _comps[ng]=_ng
  ng completion script 2> /dev/null >| "$ZSH_CACHE_DIR/completions/_ng" &|
fi
