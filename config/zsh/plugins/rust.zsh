# =============================================================================================
# ~/.config/zsh/plugins/rust.zsh
# =============================================================================================
# Rust Zsh Plugin
# This plugin provides aliases and completion for Rust.
#
# It makes managing Rust environments and packages directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# =============================================================================================
# Environment variables
# =============================================================================================
[ -d "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
