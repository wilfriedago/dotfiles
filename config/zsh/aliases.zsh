# pnpm
alias pn='pnpm'
alias pi='pnpm install'
alias pd='pnpm dev'
alias pt='pnpm test'
alias pb='pnpm build'
alias pu='pnpm update'
alias po='pnpm outdated'

# neovim
alias vim='nvim' # use neovim as vim
alias vi='nvim' # use neovim as vi

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
alias dkc='docker-compose'
alias dkcu='docker compose up'
alias dkcd='docker compose down'

# exa
alias ls='eza -a --icons --level=1' # ls with icons
alias ll="eza -al --icons" # ls -l with icons
alias l="eza -al --icons --git" # ls -l with icons and git status
alias lt="eza -al --icons --tree --level=2  --git" # ls tree with icons and git status

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
alias pubkey="cat ~/.ssh/id_ed25519.pub | pbcopy | echo '=> Copied to pasteboard.'" # copy ssh public key to clipboard
alias lzd="lazydocker" # run Docker TUI
alias llama='ollama run llama3' # run llama3

# Get macOS Software Updates, and update installed Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; pnpm add -g pnpm -g; pnpm update -g; gh extension upgrade --all; omz update'

alias afk='pmset displaysleepnow' # lock screen immediately (macOS only)

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
