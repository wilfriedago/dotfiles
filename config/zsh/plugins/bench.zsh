# =============================================================================================
# ~/.config/zsh/plugins/bench.zsh
# =============================================================================================
# Bench (frappe-bench) Zsh Plugin
# This plugin provides aliases and completion for Bench.
#
# It makes managing Frappe sites and apps directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Guards
(( $+commands[bench] )) || return

# Aliases
alias bs='bench start'
alias bw='bench watch'

alias bns='bench new-site'
alias bus='bench use'
alias bds='bench drop-site'
alias bls='bench --site'

alias bna='bench new-app'
alias bga='bench get-app'
alias bia='bench install-app'
alias bua='bench uninstall-app'
alias bla='bench list-apps'

alias bmar='bench mariadb'
alias bbk='bench backup'
alias brs='bench restore'

alias bm='bench migrate'
alias bb='bench build'
alias bup='bench update'
alias brst='bench restart'

alias bcc='bench clear-cache'
alias bcwc='bench clear-website-cache'

alias bcon='bench console'
alias bex='bench execute'

alias bes='bench enable-scheduler'
alias bdis='bench disable-scheduler'

alias bdoc='bench doctor'
alias bver='bench version'

# Completions
if [[ ! -f "$ZSH_CACHE_DIR/completions/_bench" ]]; then
  bench completions --zsh --skip-rc -y --path "$ZSH_CACHE_DIR/completions/_bench" &> /dev/null &|
fi
