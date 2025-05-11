# corepack
alias pnpm='corepack pnpm'
alias pnpx='corepack pnpx'

# pnpm
alias pn='pnpm'
alias pi='pnpm install'
alias pd='pnpm dev'
alias pt='pnpm test'
alias pb='pnpm build'
alias pu='pnpm update'
alias po='pnpm outdated'
alias pnx='pnpm dlx'

# neovim
alias vi='nvim' # use neovim as vi
alias vim='nvim' # use neovim as vim

# python
alias python='python3'
alias pip='pip3'
alias py='python3'
alias py2='python2'
alias pir='pip install -r requirements.txt'

# django
alias dj='python manage.py'
alias djdd='python manage.py dumpdata'
alias djld='python manage.py loaddata'
alias djm='python manage.py migrate'
alias djsh='python manage.py shell'
alias djsm='python manage.py schemamigration'
alias djs='python manage.py syncdb --noinput'
alias djt='python manage.py test'
alias djrs='python manage.py runserver'

# minikube
alias mk='minikube'
alias mkst='minikube start'
alias mkst-m='minikube start --memory' # Example: mkst-m 4096
alias mkst-c='minikube start --cpus'   # Example: mkst-c 4
alias mksp='minikube stop'
alias mkd='minikube delete'
alias mknd='minikube node'
alias mkip='minikube ip'
alias mks='minikube service'
alias mklo='minikube logs'
alias mkti='minikube tunnel'
alias mkdp='minikube dashboard'
alias mkstat='minikube status'
alias mkadd='minikube addons'
alias mklist='minikube addons list'
alias mkadd-e='minikube addons enable'  # Example: mkadd-e ingress
alias mkadd-d='minikube addons disable' # Example: mkadd-d metrics-server
alias mkdocker='eval $(minikube docker-env)'
alias mkssh='minikube ssh'
alias mkcache='minikube cache'
alias mkcache-a='minikube cache add'    # Example: mkcache-a nginx:latest
alias mkcache-d='minikube cache delete' # Example: mkcache-d nginx:latest
alias mkcache-l='minikube cache list'
alias mkimg='minikube image'
alias mkimg-l='minikube image ls'
alias mkimg-ls='minikube image ls -a'
alias mkns='minikube service --namespace' # Example: mkns kube-system kubernetes-dashboard
alias mkmount='minikube mount'           # Example: mkmount /local/path:/vm/path
alias mkpause='minikube pause'
alias mkunpause='minikube unpause'
alias mkver='minikube version'
alias mkup='minikube update-check'
alias mkupgrade='minikube update-context'
alias mkprofile='minikube profile'       # Example: mkprofile dev
alias mkprofile-l='minikube profile list'
alias mkstart-all='minikube start && minikube dashboard &'
alias mkclean='minikube stop && minikube delete'
alias mkrestart='minikube stop && minikube start'
alias mkrg='minikube addons enable registry'

# exa
alias ls='eza -a --icons --level=1' # ls with icons
alias ll="eza -al --icons" # ls -l with icons
alias l="eza -al --icons --git" # ls -l with icons and git status
alias lt="eza -al --icons --tree --level=3  --git" # ls tree with icons and git status

# dotdrop
alias dot='dotdrop --profile=default --cfg=~/.dotfiles/dotdrop.config.yml' # dotdrop with default profile

# zoxide
alias cd='z' # change directory with zoxide

# gradle
alias gw='./gradlew'

# terraform
alias tf='terraform'

# dotenv
alias dotlint='dotenv-linter'
alias dotvault='dotenv-vault'

# utils
alias zs='source ~/.zshrc' # source zshrc
alias rm='trash' # move to trash
alias cls='clear'
alias cat='bat -p' # cat with syntax highlighting
alias ip="curl https://ipinfo.io/json" # or /ip for plain-text ip
alias localip="ipconfig getifaddr en0" # get local ip address
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -" # test internet speed
alias flushdns="sudo killall -HUP mDNSResponder" # flush dns cache
alias pubkey="cat ~/.ssh/id_ed25519.pub | pbcopy | echo 'Public Key => Copied to clipboard.'" # copy ssh public key to clipboard
alias lzd="lazydocker" # run Docker TUI
alias yz='yazi' # run yazi
alias top='btop' # run btop
alias htop='btop' # run htop

# Get macOS Software Updates, and update installed Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; pnpm add -g pnpm -g; pnpm update -g; gh extension upgrade --all; omz update'

alias afk='pmset displaysleepnow' # lock screen immediately (macOS only)

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
