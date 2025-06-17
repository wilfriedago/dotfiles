# =============================================================================================
# ~/.config/zsh/.zshrc                                                                        #
# =============================================================================================
# Instructions to be executed when a new ZSH session is launched                              #
# Imports all plugins, aliases, helper functions, and configurations                          #
#                                                                                             #
# After editing, re-source .zshrc for new changes to take effect                              #
# For docs and more info, see: https://github.com/wilfriedago/dotfiles                        #
# =============================================================================================
# License: MIT © Wilfrieds AGO 2025 <https://wilfriedago.dev>                                 #
# =============================================================================================

# Profiling
# zmodload zsh/zprof

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)" && chmod g-rwX "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Load zinit's completion system
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load starship theme
zinit ice as"command" from"gh-r" atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" atpull"%atclone" src"init.zsh"
zinit light starship/starship

# Plugins
zinit light-mode for \
  zsh-users/zsh-autosuggestions \
  zdharma-continuum/fast-syntax-highlighting \
  Aloxaf/fzf-tab

# =============================================================================================
# Shell
# =============================================================================================

[ -f "$XDG_CONFIG_HOME/zsh/aliases.zsh" ] && source "$XDG_CONFIG_HOME/zsh/aliases.zsh" # Aliases
[ -f "$XDG_CONFIG_HOME/zsh/functions.zsh" ] && source "$XDG_CONFIG_HOME/zsh/functions.zsh" # Functions
[ -f "$XDG_CONFIG_HOME/zsh/completions.zsh" ] && source "$XDG_CONFIG_HOME/zsh/completions.zsh" # Completions
[ -f "$XDG_CONFIG_HOME/zsh/history.zsh" ] && source "$XDG_CONFIG_HOME/zsh/history.zsh" # History

# Plugins
[ -f "$XDG_CONFIG_HOME/zsh/plugins/kubectl.zsh" ] && source "$XDG_CONFIG_HOME/zsh/plugins/kubectl.zsh"
[ -f "$XDG_CONFIG_HOME/zsh/plugins/minikube.zsh" ] && source "$XDG_CONFIG_HOME/zsh/plugins/minikube.zsh"

# =============================================================================================
# Initialization
# =============================================================================================

# FNM
eval "$(fnm env --use-on-cd --shell zsh)"

# ZOXIDE
eval "$(zoxide init --cmd ${ZOXIDE_CMD_OVERRIDE:-z} zsh)"

# FZF
eval "$(fzf --zsh)"
source "$HOME/.scripts/fzf/fzf-zsh-completion.sh"

# AWS
if command -v aws_completer &> /dev/null; then
  complete -C aws_completer aws
fi

# TERRAFORM
if command -v terraform &> /dev/null; then
  complete -C "$(command -v terraform)" terraform
fi

# ARTISAN
[[ -s "$PWD/artisan" && -x "$PWD/artisan" ]] && eval "$(php artisan completion zsh)"

# =============================================================================================
# Miscellaneous
# =============================================================================================

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# Clean up PATH
typeset -U PATH
clean_path

# Profiling
# zprof
