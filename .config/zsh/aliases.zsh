# directories
alias -g ..='..'
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias -- -='cd -'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

# zoxide
alias cd='z'

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
alias vi='nvim'
alias vim='nvim'

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

# eza
alias l="eza -al --icons" # ls -l with icons
alias ls='eza -a --icons --level=1' # ls with icons
alias lt="eza -al --icons --level=3 --tree --git-ignore" # ls tree with icons

# dotdrop
alias dot='dotdrop --profile=default --cfg=~/.dotfiles/dotdrop.config.yml' # dotdrop with default profile
alias doti='dot install' # install dotfiles
alias dotu='dot update' # update dotfiles

# gradle
alias gw='./gradlew'

# terraform
alias tf='terraform'

# dotenv
alias envlint='dotenv-linter'
alias envvault='dotenv-vault'

# utils
alias zs='source ~/.zshrc' # source zshrc
alias rm='trash' # move to trash
alias cat='bat -p' # cat with syntax highlighting
alias ip="curl https://ipinfo.io/json" # or /ip for plain-text ip
alias localip="ipconfig getifaddr en0" # get local ip address
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -" # test internet speed
alias flushdns="sudo killall -HUP mDNSResponder" # flush dns cache
alias pubkey="cat ~/.ssh/id_ed25519.pub | pbcopy | echo 'Public Key => Copied to clipboard.'" # copy ssh public key to clipboard
alias lzd="lazydocker" # run Docker TUI
alias yz='yazi' # run yazi
alias claude="~/.claude/local/claude" # run local Claude Code

# Get macOS Software Updates, and update installed Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; pnpm add -g pnpm -g; pnpm update -g; gh extension upgrade --all; omz update'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
