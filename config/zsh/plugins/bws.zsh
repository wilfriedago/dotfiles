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
# - Support for multiple projects
#
# Configuration (set before sourcing):
#   BWS_CACHE_DURATION - Cache validity in seconds (default: 86400 / 24 hours)
#   BWS_AUTO_LOAD      - Auto-load secrets on shell startup (default: true)
#   BWS_SILENT         - Suppress output messages (default: true)
#   BWS_VAR_PREFIX     - Prefix for exported variables (default: none)
#   BWS_TIMEOUT        - Command timeout in seconds (default: 30)
#
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Early exit if bws is not installed
(( $+commands[bws] )) || return 1

# =============================================================================================
# Configuration
# =============================================================================================

typeset -g BWS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bws"
typeset -g BWS_CACHE_FILE="$BWS_CACHE_DIR/secrets.cache"
typeset -g BWS_CACHE_META="$BWS_CACHE_DIR/secrets.meta"
typeset -g BWS_CACHE_DURATION="${BWS_CACHE_DURATION:-86400}"
typeset -g BWS_AUTO_LOAD="${BWS_AUTO_LOAD:-true}"
typeset -g BWS_SILENT="${BWS_SILENT:-true}"
typeset -g BWS_VAR_PREFIX="${BWS_VAR_PREFIX:-}"
typeset -g BWS_TIMEOUT="${BWS_TIMEOUT:-30}"

# =============================================================================================
# Internal Utilities
# =============================================================================================

# Initialize cache directory with secure permissions
_bws_init_cache() {
  [[ -d "$BWS_CACHE_DIR" ]] || mkdir -p "$BWS_CACHE_DIR" && chmod 700 "$BWS_CACHE_DIR"
}

# Get cache age in seconds (returns large number if no cache)
_bws_cache_age() {
  [[ -f "$BWS_CACHE_META" ]] || { echo 999999; return; }
  echo $(( $(date +%s) - $(cat "$BWS_CACHE_META" 2>/dev/null || echo 0) ))
}

# Check if cache is valid
_bws_cache_valid() {
  [[ -f "$BWS_CACHE_FILE" ]] && (( $(_bws_cache_age) < BWS_CACHE_DURATION ))
}

# Conditional logging
_bws_log() {
  [[ "$BWS_SILENT" == "true" ]] || echo "$@"
}

# Error logging (always shown)
_bws_error() {
  echo "$@" >&2
}

# Retrieve credential from macOS Keychain
_bws_get_keychain_value() {
  local key="$1"
  security find-generic-password -a "$USER" -s "$key" -w 2>/dev/null
}

# Format duration for human-readable output
_bws_format_duration() {
  local seconds=$1
  if (( seconds >= 3600 )); then
    echo "$(( seconds / 3600 ))h $(( (seconds % 3600) / 60 ))m"
  elif (( seconds >= 60 )); then
    echo "$(( seconds / 60 ))m $(( seconds % 60 ))s"
  else
    echo "${seconds}s"
  fi
}

# =============================================================================================
# Core Functions
# =============================================================================================

# Fetch secrets from Bitwarden and update cache
_bw_refresh() {
  local force=false
  local silent_override=""

  while (( $# )); do
    case $1 in
      -f|--force) force=true ;;
      -s|--silent) silent_override=true ;;
      -v|--verbose) silent_override=false ;;
      -h|--help)
        echo 'Usage: bw refresh [OPTIONS]'
        echo ''
        echo 'Fetch secrets from Bitwarden Secret Manager and cache them locally.'
        echo ''
        echo 'Options:'
        echo '  -f, --force    Force refresh even if cache is valid'
        echo '  -s, --silent   Suppress output messages'
        echo '  -v, --verbose  Show detailed output'
        echo '  -h, --help     Show this help message'
        echo ''
        echo 'Environment:'
        echo '  BWS_ACCESS_TOKEN  Required. Set via keychain or environment.'
        echo '  BWS_PROJECT_ID    Required. Project ID to fetch secrets from.'
        return 0
        ;;
      *)
        _bws_error "Unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  # Apply silent override if specified
  local original_silent="$BWS_SILENT"
  [[ -n "$silent_override" ]] && BWS_SILENT="$silent_override"

  _bws_init_cache

  # Check cache validity unless forced
  if [[ "$force" != "true" ]] && _bws_cache_valid; then
    local remaining=$(( BWS_CACHE_DURATION - $(_bws_cache_age) ))
    _bws_log "🔒 Cache valid (expires in $(_bws_format_duration $remaining)), use --force to refresh"
    BWS_SILENT="$original_silent"
    return 0
  fi

  # Validate access token
  if [[ -z "$BWS_ACCESS_TOKEN" ]]; then
    BWS_ACCESS_TOKEN=$(_bws_get_keychain_value "BWS_ACCESS_TOKEN")
    if [[ -z "$BWS_ACCESS_TOKEN" ]]; then
      _bws_error "❌ BWS_ACCESS_TOKEN not found"
      _bws_error "   Set it via: security add-generic-password -a \"\$USER\" -s \"BWS_ACCESS_TOKEN\" -w \"<token>\""
      _bws_error "   Or export BWS_ACCESS_TOKEN=\"<token>\""
      BWS_SILENT="$original_silent"
      return 1
    fi
    export BWS_ACCESS_TOKEN
  fi

  # Validate project ID
  local project_id="${BWS_PROJECT_ID:-$(_bws_get_keychain_value "BWS_PROJECT_ID")}"
  if [[ -z "$project_id" ]]; then
    _bws_error "❌ BWS_PROJECT_ID not found"
    _bws_error "   Set it via: security add-generic-password -a \"\$USER\" -s \"BWS_PROJECT_ID\" -w \"<project-id>\""
    _bws_error "   Or export BWS_PROJECT_ID=\"<project-id>\""
    BWS_SILENT="$original_silent"
    return 1
  fi

  _bws_log "🔄 Fetching secrets from Bitwarden..."

  # Fetch secrets with timeout
  local secrets_json
  local start_time=$EPOCHSECONDS

  if ! secrets_json=$(timeout "$BWS_TIMEOUT" bws secret list "$project_id" 2>&1); then
    local exit_code=$?
    if (( exit_code == 124 )); then
      _bws_error "❌ Request timed out after ${BWS_TIMEOUT}s"
    else
      _bws_error "❌ Failed to fetch secrets"
      _bws_error "   Error: $secrets_json"
      _bws_error "   Verify your access token and project ID are correct"
    fi
    BWS_SILENT="$original_silent"
    return 1
  fi

  local fetch_time=$(( EPOCHSECONDS - start_time ))
  _bws_log "⏱️  Fetched in ${fetch_time}s"

  # Validate JSON response
  if ! echo "$secrets_json" | jq -e 'type == "array"' &>/dev/null; then
    _bws_error "❌ Invalid response from bws (expected JSON array)"
    _bws_error "   Response: ${secrets_json:0:200}..."
    BWS_SILENT="$original_silent"
    return 1
  fi

  # Check if any secrets were returned
  local secrets_count
  secrets_count=$(echo "$secrets_json" | jq 'length')

  if (( secrets_count == 0 )); then
    _bws_log "⚠️  No secrets found in project"
    BWS_SILENT="$original_silent"
    return 0
  fi

  # Parse secrets and generate export commands
  # Handles special characters in values properly
  local export_commands
  export_commands=$(echo "$secrets_json" | jq -r --arg prefix "$BWS_VAR_PREFIX" '
    .[] |
    "export " + $prefix + .key + "=" + (.value | @sh)
  ' 2>/dev/null)

  if [[ -z "$export_commands" ]]; then
    _bws_error "❌ Failed to parse secrets"
    BWS_SILENT="$original_silent"
    return 1
  fi

  # Write cache atomically with secure permissions
  local temp_file="$BWS_CACHE_FILE.tmp.$$"
  echo "$export_commands" > "$temp_file"
  chmod 600 "$temp_file"
  mv -f "$temp_file" "$BWS_CACHE_FILE"

  # Update cache metadata
  echo "$EPOCHSECONDS" > "$BWS_CACHE_META"
  chmod 600 "$BWS_CACHE_META"

  _bws_log "✅ Cached $secrets_count secrets (valid for $(_bws_format_duration $BWS_CACHE_DURATION))"

  BWS_SILENT="$original_silent"

  # Load into current shell
  _bw_load
}

# Load cached secrets into environment
_bw_load() {
  _bws_init_cache

  if [[ ! -f "$BWS_CACHE_FILE" ]]; then
    _bws_log "📭 No cache found, fetching..."
    _bw_refresh
    return $?
  fi

  if ! _bws_cache_valid; then
    _bws_log "⏰ Cache expired, refreshing..."
    _bw_refresh
    return $?
  fi

  # Source cached exports
  source "$BWS_CACHE_FILE"

  local secrets_count=$(grep -c '^export ' "$BWS_CACHE_FILE" 2>/dev/null || echo 0)
  local remaining=$(( BWS_CACHE_DURATION - $(_bws_cache_age) ))

  _bws_log "🔑 Loaded $secrets_count secrets (expires in $(_bws_format_duration $remaining))"
}

# Clear cache files
_bw_clear_cache() {
  local cleared=false

  if [[ -f "$BWS_CACHE_FILE" ]]; then
    # Securely remove by overwriting first
    dd if=/dev/urandom of="$BWS_CACHE_FILE" bs=1024 count=1 2>/dev/null
    rm -f "$BWS_CACHE_FILE"
    cleared=true
  fi

  [[ -f "$BWS_CACHE_META" ]] && rm -f "$BWS_CACHE_META"

  if [[ "$cleared" == "true" ]]; then
    _bws_log "🗑️  Cache cleared"
  else
    _bws_log "📭 No cache to clear"
  fi
}

# Display status information
_bw_status() {
  _bws_init_cache

  echo '🔒 Bitwarden Secret Manager Status'
  echo '══════════════════════════════════'
  echo "Cache Directory:  $BWS_CACHE_DIR"
  echo "Cache Duration:   $(_bws_format_duration $BWS_CACHE_DURATION)"
  echo "Auto Load:        $BWS_AUTO_LOAD"
  echo "Silent Mode:      $BWS_SILENT"
  echo "Timeout:          ${BWS_TIMEOUT}s"
  echo "Variable Prefix:  ${BWS_VAR_PREFIX:-<none>}"
  echo ''

  # Check credentials
  local has_token=$([[ -n "$BWS_ACCESS_TOKEN" ]] || _bws_get_keychain_value "BWS_ACCESS_TOKEN" &>/dev/null && echo "Valid" || echo "N/A")
  local has_project=$([[ -n "$BWS_PROJECT_ID" ]] || _bws_get_keychain_value "BWS_PROJECT_ID" &>/dev/null && echo "Valid" || echo "N/A")

  echo "Credentials"
  echo "───────────"
  echo "Access Token:     $has_token"
  echo "Project ID:       $has_project"
  echo ""

  echo "Cache Status"
  echo "────────────"

  if [[ -f "$BWS_CACHE_FILE" ]]; then
    local secrets_count=$(grep -c '^export ' "$BWS_CACHE_FILE" 2>/dev/null || echo 0)
    local age=$(_bws_cache_age)
    local remaining=$(( BWS_CACHE_DURATION - age ))

    if (( remaining > 0 )); then
      echo "Status:           ✅ Valid"
      echo "Secrets:          $secrets_count"
      echo "Age:              $(_bws_format_duration $age)"
      echo "Expires In:       $(_bws_format_duration $remaining)"
    else
      echo "Status:           ⚠️  Expired ($(( -remaining ))s ago)"
      echo "Secrets:          $secrets_count (stale)"
    fi
  else
    echo "Status:           ❌ No cache"
  fi

  echo ''
  echo 'Commands'
  echo '────────'
  echo '  bw refresh [-f]  Fetch and cache secrets'
  echo '  bw load          Load cached secrets'
  echo '  bw clear         Clear cache securely'
  echo '  bw status        Show this status'
  echo '  bw list          List loaded variables'
  echo '  bw get <KEY>     Get a specific secret value'
}

# List currently loaded BWS variables
_bw_list() {
  if [[ ! -f "$BWS_CACHE_FILE" ]]; then
    _bws_error "❌ No cache found. Run: bw refresh"
    return 1
  fi

  echo "🔑 Bitwarden Secrets"
  echo "════════════════════"

  local loaded=0 not_loaded=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^export\ ([^=]+)= ]]; then
      local var_name="${match[1]}"
      if [[ -n "${(P)var_name:-}" ]]; then
        echo "  ✅ $var_name"
        (( loaded++ ))
      else
        echo "  ❌ $var_name (not in environment)"
        (( not_loaded++ ))
      fi
    fi
  done < "$BWS_CACHE_FILE"

  echo ""
  echo "Total: $loaded loaded, $not_loaded not loaded"
}

# Get a specific secret value
_bw_get() {
  local key="$1"

  if [[ -z "$key" ]]; then
    _bws_error "Usage: bw get <KEY>"
    return 1
  fi

  # Add prefix if configured
  local full_key="${BWS_VAR_PREFIX}${key}"

  # Check if loaded in environment
  if [[ -n "${(P)full_key:-}" ]]; then
    echo "${(P)full_key}"
    return 0
  fi

  # Try to load from cache
  if [[ -f "$BWS_CACHE_FILE" ]]; then
    local value
    value=$(grep "^export ${full_key}=" "$BWS_CACHE_FILE" 2>/dev/null | sed "s/^export ${full_key}=//; s/^'//; s/'$//")
    if [[ -n "$value" ]]; then
      echo "$value"
      return 0
    fi
  fi

  _bws_error "❌ Secret '$key' not found"
  return 1
}

# =============================================================================================
# Main Command
# =============================================================================================

bw() {
  local cmd="$1"
  shift 2>/dev/null

  case "$cmd" in
    refresh|r)
      _bw_refresh "$@"
      ;;
    load|l)
      _bw_load "$@"
      ;;
    clear|c)
      _bw_clear_cache "$@"
      ;;
    status|s)
      _bw_status "$@"
      ;;
    list|ls)
      _bw_list "$@"
      ;;
    get|g)
      _bw_get "$@"
      ;;
    -h|--help|help|"")
      echo 'Usage: bw <command> [options]'
      echo ''
      echo 'Bitwarden Secret Manager CLI wrapper'
      echo ''
      echo 'Commands:'
      echo '  refresh, r   Fetch and cache secrets from Bitwarden'
      echo '  load, l      Load cached secrets into environment'
      echo '  clear, c     Clear cache securely'
      echo '  status, s    Show status information'
      echo '  list, ls     List loaded variables'
      echo '  get, g       Get a specific secret value'
      echo '  help         Show this help message'
      echo ''
      echo 'Examples:'
      echo '  bw refresh        # Fetch secrets (uses cache if valid)'
      echo '  bw refresh -f     # Force refresh, ignore cache'
      echo '  bw load           # Load cached secrets'
      echo '  bw get MY_SECRET  # Get specific secret value'
      echo '  bw status         # Show cache and config status'
      ;;
    *)
      _bws_error "Unknown command: $cmd"
      _bws_error "Run 'bw help' for usage information"
      return 1
      ;;
  esac
}

# =============================================================================================
# Completions
# =============================================================================================

_bws_completion_setup() {
  local completion_file="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/completions/_bws"

  # Create completion directory if needed
  [[ -d "${completion_file:h}" ]] || mkdir -p "${completion_file:h}"

  # Generate completions if missing or older than 7 days
  if [[ ! -f "$completion_file" ]] || [[ $(find "$completion_file" -mtime +7 2>/dev/null) ]]; then
    bws completions zsh > "$completion_file" 2>/dev/null &!
  fi
}

_bws_completion_setup

# =============================================================================================
# Auto-load on shell startup (background, non-blocking)
# =============================================================================================

if [[ "$BWS_AUTO_LOAD" == "true" ]]; then
  # Use zsh async loading to avoid blocking shell startup
  {
    sleep 0.2
    _bw_load
  } &!
fi

# =============================================================================================
# Export configuration for subshells
# =============================================================================================

export BWS_CACHE_DIR BWS_CACHE_DURATION BWS_AUTO_LOAD BWS_SILENT BWS_VAR_PREFIX BWS_TIMEOUT
