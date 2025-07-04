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

if command -v terraform &> /dev/null; then
  complete -C "$(command -v terraform)" terraform
fi
