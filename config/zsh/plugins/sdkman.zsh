# =============================================================================================
# ~/.config/zsh/plugins/sdkman.zsh
# =============================================================================================
# SDKMAN Zsh Plugin
# This plugin initializes SDKMAN for interactive shells only.
#
# SDKMAN init is heavy (~200-400ms) and should not run in zshenv (which affects
# every shell invocation including non-interactive scripts and subshells).
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if SDKMAN is installed
export SDKMAN_HOME="$HOME/.sdkman"
if [[ ! -s "$SDKMAN_HOME/bin/sdkman-init.sh" ]]; then
  return
fi

# Initialize SDKMAN
source "$SDKMAN_HOME/bin/sdkman-init.sh"
