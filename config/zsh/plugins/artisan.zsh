# =============================================================================================
# ~/.config/zsh/plugins/artisan.zsh
# =============================================================================================
# Artisan Zsh Plugin
# This plugin provides aliases and completion for Artisan.
#
# It makes managing Laravel Artisan commands directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================


# Check if PHP is installed
if (( ! $+commands[php] )); then
  return
fi

# Check if Composer is installed
if (( ! $+commands[composer] )); then
  return
fi

# Check if the artisan binary is available in the current directory
if [[ ! -f "artisan" ]]; then
  return
fi

# Aliases
alias a="php artisan"
alias am="php artisan migrate"
alias amf="php artisan migrate:fresh"
alias amr="php artisan migrate:refresh"
alias ams="php artisan migrate:status"
alias amr="php artisan migrate:rollback"
alias asd="php artisan db:seed"
alias acc="php artisan cache:clear"
alias avc="php artisan view:clear"
alias arl="php artisan route:list"
alias acfc="php artisan config:clear"
alias acfc="php artisan config:cache"
alias at="php artisan tinker"
alias as="php artisan serve"
alias ak="php artisan key:generate"
alias al="php artisan list"
alias amk="php artisan make:"

# Completions
if [[ ! -f "$ZSH_CACHE_DIR/completions/_artisan" ]]; then
  typeset -g -A _comps
  autoload -Uz _artisan
  _comps[artisan]=_artisan
  artisan completion zsh >| "$ZSH_CACHE_DIR/completions/_artisan" &|
fi
