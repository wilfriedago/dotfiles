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
if (( ! $+commands[terraform] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias tf='terraform'
alias tfa='terraform apply'
alias tfaa='terraform apply -auto-approve'
alias tfc='terraform console'
alias tfd='terraform destroy'
alias tff='terraform fmt'
alias tffr='terraform fmt -recursive'
alias tfi='terraform init'
alias tfir='terraform init -reconfigure'
alias tfiu='terraform init -upgrade'
alias tfiur='terraform init -upgrade -reconfigure'
alias tfo='terraform output'
alias tfp='terraform plan'
alias tfv='terraform validate'
alias tfs='terraform state'
alias tft='terraform test'
alias tfsh='terraform show'

# =============================================================================================
# Completions
# =============================================================================================
if command -v terraform &> /dev/null; then
  complete -C "$(command -v terraform)" terraform
fi
