# =============================================================================================
# ~/.config/zsh/plugins/minikube.zsh
# =============================================================================================
# Minikube Zsh Plugin
# This plugin provides aliases, functions and completion for Minikube.
#
# It makes managing local Kubernetes clusters with Minikube easier from the command line.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Minikube is installed
if (( ! $+commands[minikube] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================

# Core minikube commands
alias mk='minikube'
alias mks='minikube start'
alias mkstop='minikube stop'
alias mkrestart='minikube restart'
alias mkdelete='minikube delete'
alias mkpause='minikube pause'
alias mkunpause='minikube unpause'

# Status and info
alias mkstatus='minikube status'
alias mkip='minikube ip'
alias mkv='minikube version'
alias mkprofile='minikube profile'

# Cluster management
alias mkcfg='minikube config'
alias mkls='minikube profile list'
alias mknode='minikube node'

# Dashboard and UI
alias mkdash='minikube dashboard'
alias mkdashu='minikube dashboard --url'

# Docker daemon
alias mkdocker='eval $(minikube docker-env)'
alias mkdockeru='eval $(minikube docker-env -u)'

# SSH and logs
alias mkssh='minikube ssh'
alias mklogs='minikube logs'
alias mklogf='minikube logs -f'

# Service management
alias mksvc='minikube service'
alias mksvcls='minikube service list'

# Addons
alias mkaddons='minikube addons'
alias mkaddonsls='minikube addons list'
alias mkaddonse='minikube addons enable'
alias mkaddonsd='minikube addons disable'

# Image management
alias mkimg='minikube image'
alias mkimgload='minikube image load'
alias mkimgls='minikube image ls'
alias mkimgrm='minikube image rm'

# Tunnel (for LoadBalancer services)
alias mktunnel='minikube tunnel'

# Mount
alias mkmount='minikube mount'

# Memory and CPU
alias mkmem='minikube config get memory'
alias mkcpu='minikube config get cpus'

# =============================================================================================
# Functions
# =============================================================================================

# Start minikube with common configurations
mkstart() {
  local driver="${1:-docker}"
  local memory="${2:-4096}"
  local cpus="${3:-2}"

  echo "Starting minikube with driver: $driver, memory: ${memory}MB, cpus: $cpus"
  minikube start --driver="$driver" --memory="$memory" --cpus="$cpus"
}

# Start minikube with specific Kubernetes version
mkstartv() {
  local k8s_version="${1:-stable}"
  local driver="${2:-docker}"

  echo "Starting minikube with Kubernetes version: $k8s_version"
  minikube start --kubernetes-version="$k8s_version" --driver="$driver"
}

# Quick cluster reset (delete and start with same config)
mkreset() {
  local profile=$(minikube profile)
  echo "Resetting minikube cluster: $profile"

  # Get current config
  local driver=$(minikube config get driver 2>/dev/null || echo "docker")
  local memory=$(minikube config get memory 2>/dev/null || echo "4096")
  local cpus=$(minikube config get cpus 2>/dev/null || echo "2")

  minikube delete
  mkstart "$driver" "$memory" "$cpus"
}

# Create a new minikube profile
mkprofilecreate() {
  local profile_name="$1"
  if [[ -z "$profile_name" ]]; then
    echo "Usage: mkprofilecreate <profile-name> [driver] [memory] [cpus]"
    return 1
  fi

  local driver="${2:-docker}"
  local memory="${3:-4096}"
  local cpus="${4:-2}"

  echo "Creating new minikube profile: $profile_name"
  minikube start -p "$profile_name" --driver="$driver" --memory="$memory" --cpus="$cpus"
}

# Switch between minikube profiles
mkswitch() {
  local profile="$1"
  if [[ -z "$profile" ]]; then
    echo "Available profiles:"
    minikube profile list
    return 1
  fi

  echo "Switching to minikube profile: $profile"
  minikube profile "$profile"

  # Update kubectl context
  kubectl config use-context "$profile"
}

# Show detailed cluster information
mkinfo() {
  echo "=== Minikube Cluster Information ==="
  echo "Status: $(minikube status --format='{{.Host}}')"
  echo "IP: $(minikube ip 2>/dev/null || echo 'Not available')"
  echo "Profile: $(minikube profile)"
  echo "Kubernetes Version: $(kubectl version --short --client=false 2>/dev/null | grep Server | awk '{print $3}' || echo 'Not available')"
  echo ""
  echo "=== Configuration ==="
  echo "Driver: $(minikube config get driver 2>/dev/null || echo 'default')"
  echo "Memory: $(minikube config get memory 2>/dev/null || echo 'default')MB"
  echo "CPUs: $(minikube config get cpus 2>/dev/null || echo 'default')"
  echo ""
  echo "=== Active Addons ==="
  minikube addons list | grep enabled || echo "No addons enabled"
}

# Enable common addons quickly
mkaddonscommon() {
  echo "Enabling common minikube addons..."
  minikube addons enable dashboard
  minikube addons enable metrics-server
  minikube addons enable ingress
  minikube addons enable storage-provisioner
  echo "Common addons enabled: dashboard, metrics-server, ingress, storage-provisioner"
}

# Disable all addons
mkaddonsclear() {
  echo "Disabling all minikube addons..."
  minikube addons list | grep enabled | awk '{print $2}' | while read addon; do
    minikube addons disable "$addon"
  done
  echo "All addons disabled"
}

# Load local Docker image into minikube
mkloadimg() {
  local image="$1"
  if [[ -z "$image" ]]; then
    echo "Usage: mkloadimg <image-name:tag>"
    return 1
  fi

  echo "Loading image $image into minikube..."
  minikube image load "$image"
}

# Build and load Docker image into minikube
mkbuildload() {
  local dockerfile_path="${1:-.}"
  local image_name="$2"

  if [[ -z "$image_name" ]]; then
    echo "Usage: mkbuildload <dockerfile-path> <image-name:tag>"
    return 1
  fi

  echo "Building and loading image $image_name into minikube..."
  eval $(minikube docker-env)
  docker build -t "$image_name" "$dockerfile_path"
  echo "Image $image_name built and loaded into minikube"
}

# Quick port forward to a service
mkport() {
  local service="$1"
  local port="${2:-8080}"
  local local_port="${3:-$port}"

  if [[ -z "$service" ]]; then
    echo "Usage: mkport <service-name> [service-port] [local-port]"
    echo "Available services:"
    kubectl get services
    return 1
  fi

  echo "Port forwarding $service:$port to localhost:$local_port"
  kubectl port-forward service/"$service" "$local_port:$port"
}

# Open service in browser
mkopen() {
  local service="$1"
  if [[ -z "$service" ]]; then
    echo "Usage: mkopen <service-name>"
    echo "Available services:"
    minikube service list
    return 1
  fi

  minikube service "$service"
}

# Cleanup stopped containers and unused images
mkcleanup() {
  echo "Cleaning up minikube Docker environment..."
  eval $(minikube docker-env)
  docker system prune -f
  echo "Cleanup completed"
}

# =============================================================================================
# Completions
# =============================================================================================

if [[ ! -f "$ZSH_CACHE_DIR/completions/_minikube" ]]; then
  typeset -g -A _comps
  autoload -Uz _minikube
  _comps[minikube]=_minikube
  _comps[mk]=_minikube
  minikube completion zsh 2> /dev/null >| "$ZSH_CACHE_DIR/completions/_minikube" &|
fi

# Custom completion for our functions
_mkswitch() {
  local profiles
  profiles=($(minikube profile list -o json 2>/dev/null | jq -r '.valid[].Name' 2>/dev/null || minikube profile list 2>/dev/null | tail -n +2 | awk '{print $1}' || echo ""))
  _describe 'profiles' profiles
}

_mkopen() {
  local services
  services=($(minikube service list -o json 2>/dev/null | jq -r '.[].Name' 2>/dev/null || kubectl get services --no-headers 2>/dev/null | awk '{print $1}' || echo ""))
  _describe 'services' services
}

# Register completions
compdef _mkswitch mkswitch
compdef _mkopen mkopen
compdef _mkopen mkport
