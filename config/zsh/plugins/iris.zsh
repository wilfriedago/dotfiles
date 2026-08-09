# =============================================================================================
# ~/.config/zsh/plugins/iris.zsh
# =============================================================================================
# IRIS Zsh Plugin
# This plugin starts IRIS, an inline autocompletion overlay rendered in the TTY.
#
# IRIS is NOT a zsh plugin: `iris init zsh` emits an autostart hook that `exec iris`,
# replacing this shell with the IRIS binary, which re-spawns zsh as a child inside its
# own PTY. Everything sourced before that point is therefore paid for twice — which is
# why this file is sourced from the very TOP of .zshrc, before Zinit and Starship.
#
# It is opt-in: nothing happens unless $IRIS_ENABLE is exported. To try it:
#   IRIS_ENABLE=1 zsh
# To escape a wrapped shell that misbehaves, `exit`, or start one with IRIS_RESCUE=1.
# For docs and more info, see: https://github.com/versenilvis/iris
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Guards — interactive only, opt-in, and the binary must be on PATH.
# Note: brew's PATH is set in .zprofile, so `iris` resolves in login shells only.
[[ -o interactive ]] || return
[[ -t 1 ]] || return          # skip env probes (VSCode's `zsh -i -l -c`)
[[ -n "$IRIS_ENABLE" ]] || return
(( $+commands[iris] )) || return

# Initialization — cached by hand rather than via _cache_eval, which is defined in
# functions.zsh and is not loaded yet at the point this file has to run.
_iris_cache="$ZSH_CACHE_DIR/iris.zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
if [[ ! -f "$_iris_cache" ]] || [[ "$commands[iris]" -nt "$_iris_cache" ]]; then
  iris init zsh >| "$_iris_cache" 2>/dev/null
fi
source "$_iris_cache"   # `exec iris` happens here on the first pass
unset _iris_cache

# Set once IRIS is actually driving this shell, so .zshrc can skip zsh-autosuggestions —
# two ghost-text renderers on one prompt fight over the same screen cells.
[[ -n "$IRIS_PID" ]] && typeset -g IRIS_ACTIVE=1

# Aliases
alias irisc='iris config'        # show / manage configuration
alias irisu='iris update'        # install the latest release
alias irisl='iris changelog -n 3' # what changed recently
