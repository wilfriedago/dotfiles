# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'

# local exports
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================================
# Version managers
# =============================================================================================

# PYENV
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# =============================================================================================
# Dependencies managers
# =============================================================================================

# PNPM
export PNPM_HOME="$HOME/.pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# BUN
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH" # Add bun to PATH
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun" # This loads bun bash_completion

# =============================================================================================
# Language
# =============================================================================================

# NODE
[ -d "$PWD/node_modules/.bin" ] && export PATH="$PWD/node_modules/.bin:$PATH" # Automatically add node_modules/.bin to PATH if present

# PYTHON
[ -d "$PWD/.venv" ] && source "$PWD/.venv/bin/activate" # Automatically load Python virtual environment if available

# =============================================================================================
# External misc
# =============================================================================================

# HOMEBREW (macOS-only)
export HOMEBREW_NO_ANALYTICS=1 # Disable Homebrew analytics
export HOMEBREW_DEVELOPER=1 # Enable developer mode
export HOMEBREW_AUTO_UPDATE_SECS=604800 # 1 week
export HOMEBREW_NO_ENV_HINTS=1 # Disable Homebrew environment hints

# ANDROID
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"

# DOCKER
export DOCKER_HOST="unix://$HOME/.config/colima/default/docker.sock"

# STARSHIP
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Load fabric completions.
[ -s "$HOME/.config/fabric/fabric-bootstrap.inc" ] && source "$HOME/.config/fabric/fabric-bootstrap.inc";

# rustup
[ -d "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"