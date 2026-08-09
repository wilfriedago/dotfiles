# =============================================================================================
# ~/.config/zsh/plugins/maven.zsh
# =============================================================================================
# Maven Zsh Plugin
# This plugin provides aliases and completion for Apache Maven.
#
# It makes managing Maven projects and tasks directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Guards
(( $+commands[mvn] )) || return

# Functions
function mvn-or-mvnw() {
  local dir="$PWD" project_root="$PWD"

  while [[ "$dir" != / ]]; do
    if [[ -x "$dir/mvnw" ]]; then
      project_root="$dir"
      break
    fi
    dir="${dir:h}"
  done

  if [[ -f "$project_root/mvnw" ]]; then
    "$project_root/mvnw" "$@"
  else
    command mvn "$@"
  fi
}

# Aliases
alias mvn='mvn-or-mvnw'
alias mvnw='mvn-or-mvnw'

# Completions
compdef _mvn mvn-or-mvnw