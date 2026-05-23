# Dotfiles management recipes
# Run `just --list` to see all available commands

default_profile := "default"
config := "~/.dotfiles/dotdrop.config.yml"

# List all available recipes
_default:
  @just --list

# Deploy dotfiles for the given profile (default: default)
install profile=default_profile:
  dotdrop install --cfg={{config}} --profile={{profile}} --force

# Update dotdrop configs from deployed files
update:
  dotdrop update --cfg={{config}}

# Compare deployed files with repo
compare:
  dotdrop compare --cfg={{config}}

# Install/update all Homebrew packages
brew-sync:
  brew bundle --file ~/.dotfiles/Brewfile

# Dump currently installed packages to Brewfile
brew-dump:
  brew bundle dump --file ~/.dotfiles/Brewfile --force

# Apply macOS system settings
macos:
  bash ~/.scripts/macos/settings.sh

# Benchmark shell startup time (runs 10 iterations)
shell-bench:
  @echo "Benchmarking shell startup..."
  @for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit 2>&1; done

# Check mise runtime manager health
doctor:
  mise doctor

# Update all package managers
update-all: brew-sync
  brew update && brew upgrade && brew cleanup
  gh extension upgrade --all
  mise upgrade
