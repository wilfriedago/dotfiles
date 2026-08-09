# =============================================================================================
# ~/.config/zsh/plugins/terraform.zsh
# =============================================================================================
# Terraform Zsh Plugin
# This plugin provides aliases and completion for Terraform.
#
# It makes managing Terraform configurations and workflows directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Terraform is installed
(( $+commands[terraform] )) || return

# Aliases
alias tf='terraform'

# Completions
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform
