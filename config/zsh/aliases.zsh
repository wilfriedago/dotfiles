#!/usr/bin/env zsh

# eza
alias l="eza -al --icons" # ls -l with icons
alias ls='eza -a --icons --level=1' # ls with icons
alias lt="eza -al --icons --level=3 --tree --git-ignore" # ls tree with icons

# dotdrop
alias dot='dotdrop --profile=default --cfg=~/.dotfiles/dotdrop.config.yml' # dotdrop with default profile
alias doti='dot install' # install dotfiles
alias dotu='dot update' # update dotfiles

# dotenv
alias envlint='dotenv-linter'
alias envvault='dotenv-vault'

alias mw='./mvnw' # run Maven Wrapper
alias gw='./gradlew' # run Gradle Wrapper
alias cat='bat' # cat with syntax highlighting
alias lzd="lazydocker" # run Docker TUI
alias rm='trash' # move to trash
alias tf='terraform' # run Terraform
alias yz='yazi' # run yazi
alias artisan='php artisan' # Laravel artisan command
alias claude="~/.claude/local/claude" # run local Claude Code
alias lporg='lporg -c $XDG_CONFIG_HOME/lporg/config.yaml' # run lporg with custom config

# utils
alias zs='source ~/.zshrc' # source zshrc
alias ip="curl https://ipinfo.io/json" # or /ip for plain-text ip
alias localip="ipconfig getifaddr en0" # get local ip address
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -" # test internet speed
alias flushdns="sudo killall -HUP mDNSResponder" # flush dns cache
alias pubkey="cat ~/.ssh/id_ed25519.pub | pbcopy | echo 'Public Key => Copied to clipboard.'" # copy ssh public key to clipboard

# Get macOS Software Updates, and update installed Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a;'

alias brewupdate='brew update; brew upgrade; brew cleanup' # update Homebrew
alias ghupdate='gh extension upgrade --all' # update GitHub CLI extensions
alias npmupdate='npm install -g npm; npm update -g' # update npm and global packages
alias pnpmupdate='pnpm add -g pnpm; pnpm update -g' # update pnpm and global packages

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
