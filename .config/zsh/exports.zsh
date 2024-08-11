# `.exports` is used to provide custom variables and environment variables for the shell

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

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# sdkman
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# =============================================================================================
# Dependencies managers
# =============================================================================================

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH" # Add bun to PATH
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun" # This loads bun bash_completion

# =============================================================================================
# Language
# =============================================================================================

# Node.js
[ -d "$PWD/node_modules/.bin" ] && export PATH="$PWD/node_modules/.bin:$PATH" # Automatically add node_modules/.bin to PATH if present

# Python
[ -d "$PWD/.venv" ] && source "$PWD/.venv/bin/activate" # Automatically load Python virtual environment if available

# =============================================================================================
# External misc
# =============================================================================================

# (macOS-only) Prevent Homebrew from reporting - https://github.com/Homebrew/brew/blob/master/docs/Analytics.md
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_AUTO_UPDATE_SECS=604800 # 1 week

# android home
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# Load fabric completions.
[ -s "$HOME/.config/fabric/fabric-bootstrap.inc" ] && source "$HOME/.config/fabric/fabric-bootstrap.inc";

# =============================================================================================
# Shell
# =============================================================================================

# starship prompt
eval "$(starship init zsh)"

# gh copilot cli alias
eval "$(gh copilot alias -- zsh)"

# Load Angular CLI autocompletion.
source <(ng completion script)
