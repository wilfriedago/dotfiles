# =============================================================================================
# ~/.config/zsh/plugins/glassfish.zsh
# =============================================================================================
# GlassFish Zsh Plugin
# This plugin provides aliases and completion for GlassFish.
#
# It makes managing GlassFish projects directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Environment variables
export GLASSFISH_HOME="/opt/homebrew/opt/glassfish/libexec"
export GLASSFISH_BIN="$GLASSFISH_HOME/bin"

case ":$PATH:" in
  *":$GLASSFISH_BIN:"*) ;;
  *) export PATH="$GLASSFISH_BIN:$PATH" ;;
esac
