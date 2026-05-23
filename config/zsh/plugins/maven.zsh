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

# Check if Maven is installed
if (( ! $+commands[mvn] )); then
  return
fi

# =============================================================================================
# Functions
# =============================================================================================
# Use mvnw if available, otherwise fall back to mvn
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

alias mvn='mvn-or-mvnw'
alias mvnw='mvn-or-mvnw'
compdef _mvn mvn-or-mvnw

# =============================================================================================
# Aliases
# =============================================================================================

# General
alias mci='mvn clean install'
alias mcp='mvn clean package'
alias mct='mvn clean test'
alias mcd='mvn clean deploy'
alias mcv='mvn clean verify'
alias mcc='mvn clean compile'

# Without tests
alias mcist='mvn clean install -DskipTests'
alias mcpst='mvn clean package -DskipTests'

# Common commands
alias mi='mvn install'
alias mp='mvn package'
alias mt='mvn test'
alias mc='mvn compile'
alias mv='mvn verify'
alias mdep='mvn dependency:tree'
alias mdt='mvn dependency:tree'
alias mds='mvn dependency:sources'
alias meffpom='mvn help:effective-pom'
alias mversion='mvn versions:display-dependency-updates'
alias mplugin='mvn versions:display-plugin-updates'

# Spring Boot
alias msb='mvn spring-boot:run'
alias msbdebug='mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"'

# Quarkus
alias mqdev='mvn quarkus:dev'
