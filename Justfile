# Dotfiles management recipes
# Run `just --list` to see all available commands

default_profile := "default"
config := "~/.dotfiles/dotdrop.config.yml"

# List all available recipes
_default:
  @just --list

# Deploy dotfiles without replacing existing files
install profile=default_profile:
  dotdrop install --cfg={{config}} --profile={{profile}}

# Deploy dotfiles and explicitly replace conflicts
install-force profile=default_profile:
  dotdrop install --cfg={{config}} --profile={{profile}} --force

# Compare deployed files with repo
compare:
  dotdrop compare --cfg={{config}}

# Install/update the complete workstation
brew-sync:
  brew bundle --file ~/.dotfiles/Brewfile

# Install Zinit outside shell startup
zinit-install:
  @zinit_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"; if [ -r "$zinit_dir/zinit.zsh" ]; then echo "Zinit is already installed at $zinit_dir"; else mkdir -p "$(dirname "$zinit_dir")" && git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_dir"; fi

# Apply macOS system settings
macos:
  bash ~/.scripts/macos/settings.sh

# Benchmark shell startup time (runs 10 iterations)
shell-bench:
  @echo "Benchmarking shell startup..."
  @for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit 2>&1; done

# Validate repository configuration without changing deployed files
check:
  git diff --check
  shellcheck scripts/*.sh scripts/macos/*.sh
  bash -n scripts/*.sh scripts/macos/*.sh
  zsh -n config/zsh/*.zsh config/zsh/zshrc config/zsh/zprofile config/zsh/zshenv config/zsh/zlogin config/zsh/zlogout config/zsh/plugins/*.zsh
  gitleaks detect --source . --no-banner --redact --no-git
  dotdrop files --cfg={{config}} --profile=default >/dev/null
  dotdrop files --cfg={{config}} --profile=macos >/dev/null
  ruby -c Brewfile >/dev/null

# Update all package managers
update-all:
  brew update && brew upgrade && brew cleanup
  gh extension upgrade --all
  mise upgrade
