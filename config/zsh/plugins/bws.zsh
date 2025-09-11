# =============================================================================================
# ~/.config/zsh/plugins/bws.zsh
# =============================================================================================
# Bitwarden Secret Manager Zsh Plugin
# This plugin provides aliases, completion, and automatic secret loading for Bitwarden Secret Manager.
#
# Features:
# - Automatic secret export with intelligent caching
# - Configurable cache duration and refresh strategies
# - Utility functions for cache management
# - Secure cache storage with proper permissions
#
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Bitwarden Secret Manager is installed
if (( ! $+commands[bws] )); then
  return 1
fi

# =============================================================================================
# Load Secrets
# =============================================================================================
export BWS_ACCESS_TOKEN=$(security find-generic-password -a "$USER" -s "BWS_ACCESS_TOKEN" -w)

# =============================================================================================
# Configuration Variables
# =============================================================================================

# Cache directory
typeset -g BWS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bws"
typeset -g BWS_CACHE_FILE="$BWS_CACHE_DIR/secrets.cache"
typeset -g BWS_CACHE_META="$BWS_CACHE_DIR/secrets.meta"

# Cache duration in seconds (default: 24 hours)
typeset -g BWS_CACHE_DURATION="${BWS_CACHE_DURATION:-86400}"

# Auto-refresh on shell startup (default: enabled)
typeset -g BWS_AUTO_LOAD="${BWS_AUTO_LOAD:-true}"

# Silence output during loading (default: true)
typeset -g BWS_SILENT="${BWS_SILENT:-true}"

# Environment variable prefix (default: none)
typeset -g BWS_VAR_PREFIX="${BWS_VAR_PREFIX:-}"

# =============================================================================================
# Utility Functions
# =============================================================================================

# Create secure cache directory
_bws_init_cache() {
  if [[ ! -d "$BWS_CACHE_DIR" ]]; then
    mkdir -p "$BWS_CACHE_DIR"
    chmod 700 "$BWS_CACHE_DIR"
  fi
}

# Get cache age in seconds
_bws_cache_age() {
  if [[ ! -f "$BWS_CACHE_META" ]]; then
    echo "999999"
    return
  fi

  local cache_time=$(cat "$BWS_CACHE_META" 2>/dev/null || echo "0")
  local current_time=$(date +%s)
  echo $((current_time - cache_time))
}

# Check if cache is valid
_bws_cache_valid() {
  local age=$(_bws_cache_age)
  [[ -f "$BWS_CACHE_FILE" ]] && [[ $age -lt $BWS_CACHE_DURATION ]]
}

# Log message if not silent
_bws_log() {
  [[ "$BWS_SILENT" != "true" ]] && echo "$@"
}

# =============================================================================================
# Core Functions
# =============================================================================================

# Fetch secrets from Bitwarden and update cache
bws-refresh() {
  local force=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -f|--force)
        force=true
        shift
        ;;
      -s|--silent)
        BWS_SILENT=true
        shift
        ;;
      -h|--help)
        echo "Usage: bws-refresh [OPTIONS]"
        echo "Options:"
        echo "  -f, --force   Force refresh even if cache is valid"
        echo "  -s, --silent  Suppress output messages"
        echo "  -h, --help    Show this help message"
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        return 1
        ;;
    esac
  done

  _bws_init_cache

  # Check if refresh is needed
  if [[ "$force" != "true" ]] && _bws_cache_valid; then
    local age=$(_bws_cache_age)
    local remaining=$((BWS_CACHE_DURATION - age))
    _bws_log "🔒 Cache is valid (expires in ${remaining}s), use --force to refresh"
    return 0
  fi

  _bws_log "🔄 Fetching secrets from Bitwarden..."

  # Fetch secrets with error handling
  local secrets_json
  local personal_project_id=$(security find-generic-password -a "$USER" -s "BWS_PROJECT_ID" -w 2>/dev/null)
  if ! secrets_json=$(bws secret list 2>/dev/null); then
    echo "❌ Failed to fetch secrets from Bitwarden Secret Manager"
    echo "   Make sure you're authenticated: bws auth"
    return 1
  fi

  # Validate JSON
  if ! echo "$secrets_json" | jq empty 2>/dev/null; then
    echo "❌ Invalid JSON response from bws"
    return 1
  fi

  # Parse and cache secrets
  local secrets_count=0
  local export_commands=""

  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      export_commands+="$line"$'\n'
      ((secrets_count++))
    fi
  done < <(echo "$secrets_json" | jq -r '.[] | "export " + .key + "=\"" + .value + "\""' 2>/dev/null)

  if [[ $secrets_count -eq 0 ]]; then
    _bws_log "⚠️  No secrets found or failed to parse secrets"
    return 1
  fi

  # Write to cache with proper permissions
  {
    echo "$export_commands"
  } >| "$BWS_CACHE_FILE"
  chmod 600 "$BWS_CACHE_FILE"

  # Update cache timestamp
  date +%s >| "$BWS_CACHE_META"
  chmod 600 "$BWS_CACHE_META"

  _bws_log "✅ Cached $secrets_count secrets (valid for ${BWS_CACHE_DURATION}s)"

  # Load secrets into current shell
  bws-load
}

# Load cached secrets into environment
bws-load() {
  _bws_init_cache

  if [[ ! -f "$BWS_CACHE_FILE" ]]; then
    _bws_log "📭 No cached secrets found, fetching..."
    bws-refresh
    return $?
  fi

  if ! _bws_cache_valid; then
    local age=$(_bws_cache_age)
    _bws_log "⏰ Cache expired (age: ${age}s), refreshing..."
    bws-refresh
    return $?
  fi

  # Count secrets before loading
  local secrets_count=$(grep -c '^export ' "$BWS_CACHE_FILE" 2>/dev/null || echo "0")

  # Source the cached exports
  source "$BWS_CACHE_FILE"

  local age=$(_bws_cache_age)
  local remaining=$((BWS_CACHE_DURATION - age))
  _bws_log "🔑 Loaded $secrets_count secrets (cache expires in ${remaining}s)"
}

# Clear cache
bws-clear-cache() {
  if [[ -f "$BWS_CACHE_FILE" ]]; then
    rm -f "$BWS_CACHE_FILE"
    _bws_log "🗑️  Cleared secrets cache"
  fi

  if [[ -f "$BWS_CACHE_META" ]]; then
    rm -f "$BWS_CACHE_META"
  fi
}

# Show cache status
bws-status() {
  _bws_init_cache

  echo "🔒 Bitwarden Secret Manager Status"
  echo "=================================="
  echo "Cache Directory: $BWS_CACHE_DIR"
  echo "Cache Duration:  ${BWS_CACHE_DURATION}s"
  echo "Auto Load:       $BWS_AUTO_LOAD"
  echo "Silent Mode:     $BWS_SILENT"
  echo ""

  if [[ -f "$BWS_CACHE_FILE" ]]; then
    local secrets_count=$(grep -c '^export ' "$BWS_CACHE_FILE" 2>/dev/null || echo "0")
    local age=$(_bws_cache_age)
    local remaining=$((BWS_CACHE_DURATION - age))

    echo "Cache Status:    ✅ Valid"
    echo "Secrets Count:   $secrets_count"
    echo "Cache Age:       ${age}s"
    echo "Expires In:      ${remaining}s"

    if [[ $remaining -lt 0 ]]; then
      echo "Cache Status:    ⚠️  Expired"
    fi
  else
    echo "Cache Status:    ❌ No cache found"
  fi

  echo ""
  echo "Available commands:"
  echo "  bws-refresh     - Fetch and cache secrets"
  echo "  bws-load        - Load cached secrets"
  echo "  bws-clear-cache - Clear cache"
  echo "  bws-status      - Show this status"
  echo "  bws-list-vars   - List loaded variables"
}

# List currently loaded BWS variables
bws-list-vars() {
  if [[ ! -f "$BWS_CACHE_FILE" ]]; then
    echo "❌ No cache found"
    return 1
  fi

  echo "🔑 Currently loaded Bitwarden secrets:"
  echo "====================================="

  local count=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^export\ ([^=]+)= ]]; then
      local var_name="${match[1]}"
      if [[ -n "${(P)var_name}" ]]; then
        echo "✅ $var_name"
        ((count++))
      else
        echo "❌ $var_name (not loaded)"
      fi
    fi
  done < "$BWS_CACHE_FILE"

  echo ""
  echo "Total: $count variables loaded"
}

# =============================================================================================
# Aliases
# =============================================================================================

alias bwsr='bws-refresh'
alias bwsl='bws-load'
alias bwss='bws-status'
alias bwsc='bws-clear-cache'
alias bwsv='bws-list-vars'

# =============================================================================================
# Completions
# =============================================================================================

if [[ ! -f "$ZSH_CACHE_DIR/completions/_bws" ]]; then
  typeset -g -A _comps
  autoload -Uz _bws
  _comps[bws]=_bws
  bws completions zsh >| "$ZSH_CACHE_DIR/completions/_bws" &|
fi

# =============================================================================================
# Auto-load on shell startup
# =============================================================================================

if [[ "$BWS_AUTO_LOAD" == "true" ]]; then
  # Load secrets in background to avoid blocking shell startup
  {
    # Small delay to let shell finish loading
    sleep 0.1
    bws-load
  } &!
fi

# =============================================================================================
# Export configuration for subshells
# =============================================================================================

export BWS_CACHE_DIR BWS_CACHE_DURATION BWS_AUTO_LOAD BWS_SILENT BWS_VAR_PREFIX
