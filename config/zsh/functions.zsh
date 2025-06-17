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

# clone a repo from url (https|git) and cd into it
function clone() {
	local url=$1;
	local repo=$(echo $url | awk -F/ '{print $NF}' | sed -e 's/.git$//');
	git clone $url $repo && cd $repo;
}

# Load completions for common tools if not already loaded
load_completion() {
  local cmd="$1"
  local completion_file="$ZSH_COMPLETIONS_DIR/_$cmd"

  if [[ ! -f "$completion_file" ]] && command -v "$cmd" &> /dev/null; then
    case "$cmd" in
      bun)
        bun completions > "$completion_file" 2>/dev/null
        ;;
      docker)
        docker completion zsh > "$completion_file" 2>/dev/null
        ;;
      kubectl)
        kubectl completion zsh > "$completion_file" 2>/dev/null
        ;;
      gh)
        gh completion -s zsh > "$completion_file" 2>/dev/null
        ;;
      helm)
        helm completion zsh > "$completion_file" 2>/dev/null
        ;;
      terraform)
        complete -C terraform terraform 2>/dev/null
        ;;
      aws)
        complete -C 'aws_completer' aws 2>/dev/null
        ;;
      *)
        # Try generic completion generation
        "$cmd" completion > "$completion_file" 2>/dev/null || \
        "$cmd" completions > "$completion_file" 2>/dev/null || \
        "$cmd" completion zsh > "$completion_file" 2>/dev/null || \
        "$cmd" --completion zsh > "$completion_file" 2>/dev/null || \
        "$cmd" completion -s zsh > "$completion_file" 2>/dev/null || \
        "$cmd" completions --shell zsh > "$completion_file" 2>/dev/null
        ;;
    esac

    if [[ -f "$completion_file" ]]; then
      source "$completion_file"
      echo "✓ Loaded completion for $cmd"
    fi
  fi
}

# Auto-load completions for common tools
autoload_completions() {
  local tools=(bun docker fnm gh helm kubectl minikube terraform aws)
  for tool in $tools; do
    if command -v "$tool" &> /dev/null; then
      load_completion "$tool"
    fi
  done
}

# Update completions for all tools
update_completions() {
  echo "🔄 Updating completions..."

  # Remove old completions
  rm -f "$ZSH_COMPLETIONS_DIR"/_*

  # Regenerate completions
  autoload_completions

  # Rebuild completion cache
  rm -f "${ZDOTDIR:-$HOME}/.zcompdump"
  compinit

  echo "✅ Completions updated!"
}
