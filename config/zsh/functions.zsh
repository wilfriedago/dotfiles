#!/usr/bin/env zsh

# `.functions` provides helper functions for the shell

# Cache the output of an eval command to avoid forking on every shell start.
# Usage: _cache_eval <name> <command> <binary_path>
# Invalidates cache when the binary is newer than the cache file.
_cache_eval() {
  local name="$1" cmd="$2" binary="$3"
  local cache_file="$ZSH_CACHE_DIR/${name}.zsh"
  [[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
  if [[ ! -f "$cache_file" ]] || [[ -n "$binary" && "$binary" -nt "$cache_file" ]]; then
    eval "$cmd" >| "$cache_file" 2>/dev/null
  fi
  source "$cache_file"
}

# Point a $XDG_BIN_HOME shim at an executable that ships inside a macOS app bundle.
# Usage: _link_app_bin <name> <target>
#
# App bundles must not go on $PATH themselves: their Resources directories carry
# unrelated executables — ChatGPT.app ships its own `rg`, which would shadow
# Homebrew's ripgrep — and the ones versioned per release (Claude Code) move on
# every update, leaving a dead $PATH entry behind. A single symlink in
# $XDG_BIN_HOME, already on $PATH from zshenv, exposes exactly one command and is
# re-resolved on every shell start, so an app update is picked up on the next one.
#
# Costs a stat in the common case: `-ef` compares the resolved files, no fork.
_link_app_bin() {
  local name="$1" target="$2" link="${XDG_BIN_HOME}/${1}"
  [[ -x "$target" ]] || return 1
  # Never clobber a real file — a manual install or another package manager owns it.
  [[ -e "$link" && ! -L "$link" ]] && return 1
  [[ -L "$link" && "$link" -ef "$target" ]] && return 0
  [[ -d "$XDG_BIN_HOME" ]] || mkdir -p "$XDG_BIN_HOME"
  ln -sfn "$target" "$link" && rehash
}

# iterate over directories and pulls git repositories
rgp () {
  find . -name ".git" -type d | sed 's/\/.git//' |  xargs -P10 -I{} git -C {} pull
}

# delete merged branches locally and remotely
rgc () {
  git branch -r --merged | grep -v '\*\|master\|main\|develop' | sed 's/origin\///' | xargs -n 1 git push --delete origin
  git fetch -p
}

# empty the Trash
osclean () {
  rm -rf ~/.Trash/*
}

# cd into whatever is the forefront Finder window
cdf () {
  local path=$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')
  z "$path"
}

# kill a process by its listening port
killport () {
  local port=$1
  if [ -z "$port" ]; then
    echo "Usage: killport <port>"
    return 1
  fi
  lsof -ti:"$port" | xargs -r kill
}

# load `.env` file from a filename passed as an argument
loadenv () {
  while read line; do
    if [ "${line:0:1}" = '#' ]; then
      continue  # ignore comments
    fi
    export $line > /dev/null
  done < "$1"
  echo "Environment variables loaded from $1."
}
