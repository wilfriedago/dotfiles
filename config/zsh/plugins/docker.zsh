# =============================================================================================
# ~/.config/zsh/plugins/docker.zsh
# =============================================================================================
# Docker Zsh Plugin
# This plugin provides aliases and completion for Docker.
#
# It makes managing Docker containers, images, networks, and volumes directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Docker is installed
if (( ! $+commands[docker] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias dk='docker'
alias dkbl='docker build'
alias dkin='docker container inspect'
alias dkcls='docker container ls'
alias dclsa='docker container ls -a'
alias dib='docker image build'
alias dii='docker image inspect'
alias dils='docker image ls'
alias dipu='docker image push'
alias dipru='docker image prune -a'
alias dirm='docker image rm'
alias dit='docker image tag'
alias dlo='docker container logs'
alias dnc='docker network create'
alias dncn='docker network connect'
alias dndcn='docker network disconnect'
alias dni='docker network inspect'
alias dnls='docker network ls'
alias dnrm='docker network rm'
alias dpo='docker container port'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dpu='docker pull'
alias dr='docker container run'
alias drit='docker container run -it'
alias drm='docker container rm'
alias dst='docker container start'
alias drs='docker container restart'
alias dsta='docker stop $(docker ps -q)'
alias dstp='docker container stop'
alias dsts='docker stats'
alias dtop='docker top'
alias dvi='docker volume inspect'
alias dvls='docker volume ls'
alias dvprune='docker volume prune'
alias dxc='docker container exec'
alias dxcit='docker container exec -it'
alias dco="docker compose"
alias dcb="docker compose build"
alias dce="docker compose exec"
alias dcps="docker compose ps"
alias dcrestart="docker compose restart"
alias dcrm="docker compose rm"
alias dcr="docker compose run"
alias dcstop="docker compose stop"
alias dcup="docker compose up"
alias dcupb="docker compose up --build"
alias dcupd="docker compose up -d"
alias dcupdb="docker compose up -d --build"
alias dcdn="docker compose down"
alias dcl="docker compose logs"
alias dclf="docker compose logs -f"
alias dclF="docker compose logs -f --tail 0"
alias dcpull="docker compose pull"
alias dcstart="docker compose start"
alias dck="docker compose kill"

# =============================================================================================
# Completions
# =============================================================================================
if [[ ! -f "$ZSH_CACHE_DIR/completions/_docker" ]]; then
  typeset -g -A _comps
  autoload -Uz _docker
  _comps[docker]=_docker
  _comps[dk]=_docker
  docker completion zsh >| "$ZSH_CACHE_DIR/completions/_docker" &|
fi
