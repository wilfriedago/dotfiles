# =============================================================================================
# ~/.config/zsh/plugins/gradle.zsh
# =============================================================================================
# Gradle Zsh Plugin
# This plugin provides aliases and completion for Gradle.
#
# It makes managing Gradle projects and tasks directly from the command line easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Gradle is installed
if (( ! $+commands[gradle] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================
alias gw='./gradlew'
alias gradlew='./gradlew'
alias gradle='gradle-or-gradlew'

# =============================================================================================
# Functions
# =============================================================================================
# Use gradlew if available, otherwise fall back to gradle
function gradle-or-gradlew() {
  # taken from https://github.com/gradle/gradle-completion
  local dir="$PWD" project_root="$PWD"
  while [[ "$dir" != / ]]; do
    if [[ -x "$dir/gradlew" ]]; then
      project_root="$dir"
      break
    fi
    dir="${dir:h}"
  done

  # if gradlew found, run it instead of gradle
  if [[ -f "$project_root/gradlew" ]]; then
    "$project_root/gradlew" "$@"
  else
    command gradle "$@"
  fi
}

alias gradle=gradle-or-gradlew
compdef _gradle gradle-or-gradlew
