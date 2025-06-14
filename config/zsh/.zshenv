# Set XDG directories
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_BIN_HOME="${HOME}/.local/bin"
export XDG_LIB_HOME="${HOME}/.local/lib"
export XDG_CACHE_HOME="${HOME}/.cache"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# GPG
export GPG_TTY=$(tty)

# Preferred editor for local and remote sessions
export PAGER="less"
export EDITOR="nvim"
export VISUAL=$EDITOR
export GIT_EDITOR=$EDITOR
export KUBE_EDITOR=$EDITOR
export BUNDLER_EDITOR=$EDITOR

# local exports
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Man
export MANPATH="/usr/local/man:$MANPATH"

# STARSHIP
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# =============================================================================================
# Programming languages
# =============================================================================================

# GO
export GOROOT="/usr/local/go"
export GOPATH="$HOME/.go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH" # Add Go binaries to PATH

# PYTHON
[ -d "$PWD/.venv" ] && source "$PWD/.venv/bin/activate" # Automatically load Python virtual environment if available

# RUST
[ -d "$HOME/.cargo/env" ] && source "$HOME/.cargo/env" # Load Rust environment

# =============================================================================================
# Versions managers
# =============================================================================================

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# =============================================================================================
#  Runtime environments
# =============================================================================================

# NODE Binaries
[ -d "$PWD/node_modules/.bin" ] && export PATH="$PWD/node_modules/.bin:$PATH"

# =============================================================================================
# Package managers
# =============================================================================================

# HOMEBREW
export HOMEBREW_NO_ANALYTICS=1 # Disable Homebrew analytics
export HOMEBREW_DEVELOPER=1 # Enable developer mode
export HOMEBREW_AUTO_UPDATE_SECS=604800 # 1 week
export HOMEBREW_NO_ENV_HINTS=1 # Disable Homebrew environment hints

# PNPM
export PNPM_HOME="$HOME/.pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# =============================================================================================
# Miscellaneous
# =============================================================================================

# ANDROID
export ANDROID_HOME="${HOME}/Library/Android/sdk"
export PATH="${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${PATH}"

# FZF
if [[ ! "$PATH" == */opt/fzf/bin* ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/fzf/bin:$PATH"
fi

# ZSH
export ZSH_COMPLETIONS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/completions"
[[ ! -d "$ZSH_COMPLETIONS_DIR" ]] && mkdir -p "$ZSH_COMPLETIONS_DIR"
fpath=("$ZSH_COMPLETIONS_DIR" $fpath)
