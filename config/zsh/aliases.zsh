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

# git
alias gs='git status'
alias gd='git diff'
alias gl='git log'
alias gc='git checkout'
alias gp='git push'
alias gm='git merge'
alias gpl='git pull --rebase'
alias gca='git add . && git commit --amend'

# docker
alias dk='docker'
alias dkps='docker ps'
alias dkpsa='docker ps -a'
alias dkx='docker exec -it'
alias dki='docker images'
alias dkrun='docker run'
alias dkclean='docker system prune -a --volumes'
alias dkc='docker-compose'
alias dkcu='docker compose up'
alias dkcd='docker compose down'

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

# kubectl
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods --all-namespaces'
alias kgpw='kubectl get pods -o wide'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kgi='kubectl get ingress'
alias kgc='kubectl get configmaps'
alias kgs='kubectl get secrets'
alias kgns='kubectl get namespaces'
alias kd='kubectl describe'
alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kds='kubectl describe service'
alias kdn='kubectl describe node'
alias kdi='kubectl describe ingress'
alias kdc='kubectl describe configmap'
alias kdsec='kubectl describe secret'
alias ka='kubectl apply -f'
alias kd='kubectl delete'
alias kdp='kubectl delete pod'
alias kdd='kubectl delete deployment'
alias kds='kubectl delete service'
alias kdi='kubectl delete ingress'
alias kdc='kubectl delete configmap'
alias kdsec='kubectl delete secret'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kctx='kubectl config use-context'
alias kgctx='kubectl config get-contexts'
alias ksctx='kubectl config set-context'
alias kcns='kubectl config set-context --current --namespace'
alias kpf='kubectl port-forward'
alias ktp='kubectl top pod'
alias ktn='kubectl top node'
alias krs='kubectl rollout status'
alias krh='kubectl rollout history'
alias kru='kubectl rollout undo'
alias krd='kubectl rollout restart deployment'

alias k-mk='kubectl config use-context minikube'
alias k-default='kubectl config set-context --current --namespace default'
alias k-kube-system='kubectl config set-context --current --namespace kube-system'
alias kgp-yaml='kubectl get pod -o yaml'
alias kgd-yaml='kubectl get deployment -o yaml'
alias kgs-yaml='kubectl get service -o yaml'
alias kgc-yaml='kubectl get configmap -o yaml'
alias kgi-yaml='kubectl get ingress -o yaml'
alias kgns-yaml='kubectl get namespaces -o yaml'

# exa
alias ls='eza -a --icons --level=1' # ls with icons
alias ll="eza -al --icons" # ls -l with icons
alias l="eza -al --icons --git" # ls -l with icons and git status
alias lt="eza -al --icons --tree --level=3  --git" # ls tree with icons and git status

# dotdrop
alias dot='dotdrop --profile=default --cfg=~/.dotfiles/config/dotdrop/config.yml' # dotdrop with default profile

# zoxide
alias cd='z' # change directory with zoxide

# gradle
alias gw='./gradlew'

# terraform
alias tf='terraform'

# doctl
alias doc='doctl'

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
alias pubkey="cat ~/.ssh/id_ed25519.pub | pbcopy | echo '=> Copied to clipboard.'" # copy ssh public key to clipboard
alias lzd="lazydocker" # run Docker TUI
alias llama='ollama run lama3' # run lama3
alias y='yazi' # run yazi

# Get macOS Software Updates, and update installed Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; pnpm add -g pnpm -g; pnpm update -g; gh extension upgrade --all; omz update'

alias afk='pmset displaysleepnow' # lock screen immediately (macOS only)

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
