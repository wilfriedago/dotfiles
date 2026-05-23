# dotdrop
alias dot='dotdrop --profile=default --cfg=~/.dotfiles/dotdrop.config.yml' # dotdrop with default profile
alias doti='dot install' # install dotfiles
alias dotu='dot update' # update dotfiles

alias cat='bat' # cat with syntax highlighting
alias lzd="lazydocker" # run Docker TUI
alias rm='trash' # move to trash
alias yz='yazi' # run yazi

# utils
alias zs='source ~/.zshrc' # source zshrc
alias ip="curl https://ipinfo.io/json" # or /ip for plain-text ip
alias localip="ipconfig getifaddr en0" # get local ip address
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -" # test internet speed
alias flushdns="sudo killall -HUP mDNSResponder" # flush dns cache
alias pubkey="cat ~/.ssh/id_ed25519.pub | pbcopy | echo 'Public Key => Copied to clipboard.'" # copy ssh public key to clipboard
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'

# Get macOS Software Updates, and update installed Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a;'

alias brewupdate='brew update; brew upgrade; brew cleanup' # update Homebrew
alias ghupdate='gh extension upgrade --all' # update GitHub CLI extensions

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
