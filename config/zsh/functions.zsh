# `.functions` provides helper functions for the shell

# iterate over directories and pulls git repositories
rgp () {
  find . -name ".git" -type d | sed 's/\/.git//' |  xargs -P10 -I{} git -C {} pull
}

# delete merged branches locally and remotely
rgc () {
  git branch -r --merged | grep -v '\*\|master\|main\|develop' | sed 's/origin\///' | xargs -n 1 git push --delete origin
  git fetch -p
}

# delete backup files
bakclean () {
  find . -name "*.*.dotdropbak" -type f -delete
  find . -name "*.dotdropbak" -type f -delete
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

# show pretty `man` page
man () {
  env \
    LESS_TERMCAP_mb=$(printf '\e[1;31m') \
    LESS_TERMCAP_md=$(printf '\e[1;31m') \
    LESS_TERMCAP_me=$(printf '\e[0m') \
    LESS_TERMCAP_se=$(printf '\e[0m') \
    LESS_TERMCAP_so=$(printf '\e[1;44;33m') \
    LESS_TERMCAP_ue=$(printf '\e[0m') \
    LESS_TERMCAP_us=$(printf '\e[1;32m') \
      man "$@"
}

# lazygit with auto-cd, usefull when you're working with worktrees
lzg() {
  export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

  lazygit "$@"

  if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
    cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
    rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
  fi
}

# https://github.com/nvm-sh/nvm#zsh
autoload -U add-zsh-hook

# Call `nvm use` automatically in a directory with a `.nvmrc` file
load-nvmrc() {
  if nvm -v &> /dev/null; then
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use --silent
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      nvm use default --silent
    fi
  fi
}

type -a nvm > /dev/null && add-zsh-hook chpwd load-nvmrc
type -a nvm > /dev/null && load-nvmrc

# Clean the PATH variable by removing non-existent directories
clean_path() {
  # Split PATH into an array
  local path_parts=("${(@s/:/)PATH}")
  # Filter out non-existent directories
  local clean_parts=()

  for part in $path_parts; do
    if [[ -d "$part" ]]; then
      clean_parts+=("$part")
    fi
  done

  # Rejoin with colon separator
  export PATH="${(j/:/)clean_parts}"
  echo "PATH cleaned. Removed non-existent directories."
}

# Clean the PATH variable silently
clean_path() {
  local path_parts=("${(@s/:/)PATH}")
  local clean_parts=()

  for part in $path_parts; do
    if [[ -d "$part" ]]; then
      clean_parts+=("$part")
    fi
  done

  export PATH="${(j/:/)clean_parts}"
}
