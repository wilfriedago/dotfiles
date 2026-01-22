# =============================================================================================
# ~/.config/zsh/plugins/lmstudio.zsh
# =============================================================================================
# LM Studio CLI Zsh Plugin
# This plugin provides aliases and completion for the LM Studio CLI.
#
# It makes working with the LM Studio directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# =============================================================================================
# Environment variables
# =============================================================================================
export LMSTUDIO_HOME="/Users/wilfriedago/.lmstudio"
case ":$PATH:" in
  *":$LMSTUDIO_HOME/bin:"*) ;;
  *) export PATH="$LMSTUDIO_HOME/bin:$PATH" ;;
esac
