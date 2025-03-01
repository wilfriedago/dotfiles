# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'

# local exports
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================================
# Programming languages
# =============================================================================================

# GO
export GOROOT="/usr/local/go"
export GOPATH="$HOME/.go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH" # Add Go binaries to PATH

# =============================================================================================
# Version managers
# =============================================================================================

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm

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
# Programming languages utils
# =============================================================================================

# NODE
[ -d "$PWD/node_modules/.bin" ] && export PATH="$PWD/node_modules/.bin:$PATH" # Automatically add node_modules/.bin to PATH if present

# PYTHON
[ -d "$PWD/.venv" ] && source "$PWD/.venv/bin/activate" # Automatically load Python virtual environment if available

# =============================================================================================
# Tools
# =============================================================================================

# HOMEBREW (macOS-only)
export HOMEBREW_NO_ANALYTICS=1 # Disable Homebrew analytics
export HOMEBREW_DEVELOPER=1 # Enable developer mode
export HOMEBREW_AUTO_UPDATE_SECS=604800 # 1 week
export HOMEBREW_NO_ENV_HINTS=1 # Disable Homebrew environment hints

# ANDROID
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"

# STARSHIP
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# RUST
[ -d "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# FLUTTER
export FLUTTER_HOME="$HOME/.flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

# Since I'm not a Google Chrome user, I'll using Brave Browser instead
export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
