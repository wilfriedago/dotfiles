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

# delete Python cache directories
pyclean () {
  find . \
    | grep -E '(__pycache__|\.(mypy_)?cache|\.hypothesis\.py[cod]|\.(pytest_)?cache|\.ropeproject|\.(ruff_)?cache|\.(ipynb_)?checkpoints|.coverage|coverage.xml$)' \
    | xargs rm -rf
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

# Useful function to quickly deploy apps
mkdeploy() {
  if [ -z "$1" ]; then
    echo "Usage: mkdeploy [deployment_yaml_file]"
    return 1
  fi
  kubectl apply -f "$1"
}

# Configure kubectl to use minikube's built-in Docker daemon
mkdocker-use() {
  eval $(minikube -p minikube docker-env)
  echo "Now using minikube's Docker daemon. Images built now will be available in minikube."
}

# Reset Docker env when you're done
mkdocker-unuse() {
  eval $(minikube -p minikube docker-env --unset)
  echo "Now using your host's Docker daemon."
}

# Function to open a service in browser
mkopen() {
  if [ -z "$1" ]; then
    echo "Usage: mkopen [service_name] [namespace (optional)]"
    return 1
  fi

  if [ -z "$2" ]; then
    minikube service "$1" --url | xargs open
  else
    minikube service "$1" -n "$2" --url | xargs open
  fi
}

# For creating minikube with specific parameters
mkcreate() {
  local memory=${1:-2048}
  local cpus=${2:-2}
  local driver=${3:-docker}

  minikube start --memory "$memory" --cpus "$cpus" --driver "$driver"
  echo "Minikube started with ${memory}MB memory, ${cpus} CPUs using ${driver} driver"
}

# Get node info
mknodeinfo() {
  minikube ssh "cat /proc/cpuinfo && free -m && df -h"
}

# Useful functions
kns() {
  if [ -z "$1" ]; then
    kubectl get ns
  else
    kubectl config set-context --current --namespace "$1"
    echo "Switched to namespace: $1"
  fi
}

# Watch pods or resources
kw() {
  local resource=${1:-pods}
  shift
  kubectl get "$resource" "$@" --watch
}

# Get all resources in a namespace
kget-all() {
  local namespace=${1:-default}
  echo "Pods in $namespace namespace:"
  kubectl get pods -n "$namespace"
  echo "\nDeployments in $namespace namespace:"
  kubectl get deployments -n "$namespace"
  echo "\nServices in $namespace namespace:"
  kubectl get services -n "$namespace"
  echo "\nIngresses in $namespace namespace:"
  kubectl get ingress -n "$namespace" 2>/dev/null || echo "No ingresses found"
  echo "\nConfigMaps in $namespace namespace:"
  kubectl get configmaps -n "$namespace"
}

# Create a quick pod for debugging
kdebug() {
  kubectl run debug-pod --rm -i --tty --image=alpine -- sh
}

# Create a quick pod with tools
kdebug-full() {
  kubectl run debug-pod --rm -i --tty --image=nicolaka/netshoot -- bash
}

# Get pod IP addresses
kip() {
  kubectl get pods -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP
}

# Get node resource usage
knodes() {
  kubectl top nodes
  echo ""
  kubectl get nodes
}

# Interactive pod selection
kpods() {
  local pod=$(kubectl get pods | tail -n +2 | fzf | awk '{print $1}')
  if [[ -n $pod ]]; then
    echo "Selected pod: $pod"
    echo "Available actions:"
    echo "1) Describe pod"
    echo "2) Logs"
    echo "3) Follow logs"
    echo "4) Exec into pod"
    echo "5) Delete pod"
    echo "6) Port forward"
    read -k 1 "action?Action: "
    echo ""

    case $action in
      1) kubectl describe pod $pod ;;
      2) kubectl logs $pod ;;
      3) kubectl logs -f $pod ;;
      4) kubectl exec -it $pod -- sh ;;
      5) kubectl delete pod $pod ;;
      6)
        read "port?Local port: "
        read "pod_port?Pod port: "
        kubectl port-forward $pod $port:$pod_port
        ;;
      *) echo "Invalid action" ;;
    esac
  fi
}

# Interactive namespace switching
knamespace() {
  local ns=$(kubectl get ns | tail -n +2 | fzf | awk '{print $1}')
  if [[ -n $ns ]]; then
    kubectl config set-context --current --namespace $ns
    echo "Switched to namespace: $ns"
  fi
}

# Interactive context switching (including minikube)
kcontext() {
  local ctx=$(kubectl config get-contexts | tail -n +2 | fzf | awk '{print $1}')
  if [[ -n $ctx ]]; then
    kubectl config use-context $ctx
    echo "Switched to context: $ctx"
  fi
}

# Interactive minikube addon toggle
mkaddon() {
  local addon=$(minikube addons list | grep -v "║" | grep -v "=" | awk '{print $1}' | fzf)
  if [[ -n $addon ]]; then
    echo "1) Enable $addon"
    echo "2) Disable $addon"
    read -k 1 "action?Action: "
    echo ""

    case $action in
      1) minikube addons enable $addon ;;
      2) minikube addons disable $addon ;;
      *) echo "Invalid action" ;;
    esac
  fi
}

# Interactive service browser
mkservices() {
  local ns=$(kubectl get ns | tail -n +2 | awk '{print $1}' | fzf --prompt="Select namespace: ")
  if [[ -n $ns ]]; then
    local svc=$(kubectl get svc -n $ns | tail -n +2 | awk '{print $1}' | fzf --prompt="Select service: ")
    if [[ -n $svc ]]; then
      minikube service $svc -n $ns
    fi
  fi
}

# Interactive k8s resource viewer with preview
kview() {
  local -a resources=("pods" "deployments" "services" "configmaps" "secrets" "ingress" "namespaces" "nodes")
  local resource=$(printf "%s\n" "${resources[@]}" | fzf --prompt="Select resource type: ")

  if [[ -n $resource ]]; then
    local ns=""
    if [[ $resource != "namespaces" && $resource != "nodes" ]]; then
      ns=$(kubectl get ns | tail -n +2 | awk '{print $1}' | fzf --prompt="Select namespace: ")
    fi

    if [[ -n $ns || $resource == "namespaces" || $resource == "nodes" ]]; then
      local ns_opt=""
      [[ -n $ns ]] && ns_opt="-n $ns"

      local item=$(kubectl get $resource $ns_opt | tail -n +2 | fzf --preview "kubectl describe $resource $ns_opt \$(echo {} | awk '{print \$1}')" --preview-window=right:70%)

      if [[ -n $item ]]; then
        local name=$(echo $item | awk '{print $1}')
        kubectl describe $resource $ns_opt $name | less
      fi
    fi
  fi
}
