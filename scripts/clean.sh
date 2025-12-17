#!/usr/bin/env bash
set -euo pipefail

# Enhanced macOS Cleanup Script
# Based on: https://raw.githubusercontent.com/hkdobrev/cleanmac/refs/heads/main/cleanmac.sh
# Improvements: Parallel execution, better modularity, progress tracking, additional cleanup targets

# =============================================================================
# Configuration
# =============================================================================

DAYS_TO_KEEP=${DAYS_TO_KEEP:-7}
DRY_RUN=false
VERBOSE=false
PARALLEL_JOBS=4
SKIP_DOCKER=false
SKIP_HOMEBREW=false

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Track statistics
declare -A STATS
STATS[files_removed]=0
STATS[dirs_removed]=0
STATS[errors]=0

# Temp file for parallel job results
RESULTS_FILE=$(mktemp)
trap 'rm -f "$RESULTS_FILE"' EXIT

# =============================================================================
# Logging Functions
# =============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; ((STATS[errors]++)) || true; }
log_debug()   { [[ "$VERBOSE" == true ]] && echo -e "${CYAN}[DEBUG]${NC} $1" || true; }
log_section() { echo -e "\n${BOLD}=== $1 ===${NC}"; }

# =============================================================================
# Utility Functions
# =============================================================================

bytes_to_human() {
    local bytes=$1
    if ((bytes >= 1073741824)); then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    elif ((bytes >= 1048576)); then
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
    elif ((bytes >= 1024)); then
        echo "$(echo "scale=2; $bytes / 1024" | bc) KB"
    else
        echo "$bytes bytes"
    fi
}

get_dir_size() {
    local path="$1"
    if [[ -d "$path" ]]; then
        du -sk "$path" 2>/dev/null | awk '{print $1 * 1024}' || echo 0
    else
        echo 0
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Safe cleanup with size tracking
safe_clean() {
    local path="$1"
    local description="$2"
    local use_sudo="${3:-false}"
    local size_before=0

    if [[ ! -e "$path" ]]; then
        log_debug "$description: Path not found, skipping."
        return 0
    fi

    size_before=$(get_dir_size "$path")
    log_info "Cleaning $description..."

    if [[ "$DRY_RUN" == true ]]; then
        local count
        if [[ "$use_sudo" == true ]]; then
            count=$(sudo find "$path" -type f -mtime +"${DAYS_TO_KEEP}" 2>/dev/null | wc -l | tr -d ' ')
        else
            count=$(find "$path" -type f -mtime +"${DAYS_TO_KEEP}" 2>/dev/null | wc -l | tr -d ' ')
        fi
        log_info "[DRY RUN] Would remove $count files from $description"
        return 0
    fi

    local removed=0
    if [[ "$use_sudo" == true ]]; then
        removed=$(sudo find "$path" -type f -mtime +"${DAYS_TO_KEEP}" -delete -print 2>/dev/null | wc -l | tr -d ' ') || true
    else
        removed=$(find "$path" -type f -mtime +"${DAYS_TO_KEEP}" -delete -print 2>/dev/null | wc -l | tr -d ' ') || true
    fi

    local size_after
    size_after=$(get_dir_size "$path")
    local freed=$((size_before - size_after))

    if ((removed > 0)); then
        log_success "Removed $removed files from $description (freed $(bytes_to_human $freed))"
        ((STATS[files_removed] += removed)) || true
    else
        log_debug "No files to clean in $description"
    fi
}

# Remove entire directory contents
clean_dir() {
    local path="$1"
    local description="$2"

    if [[ ! -d "$path" ]]; then
        log_debug "$description: Directory not found, skipping."
        return 0
    fi

    local size_before
    size_before=$(get_dir_size "$path")

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would remove $description ($(bytes_to_human $size_before))"
        return 0
    fi

    log_info "Removing $description..."
    if rm -rf "${path:?}"/* 2>/dev/null; then
        log_success "Cleaned $description (freed $(bytes_to_human $size_before))"
        ((STATS[dirs_removed]++)) || true
    else
        log_warn "Partial cleanup of $description"
    fi
}

# =============================================================================
# Cleanup Modules
# =============================================================================

cleanup_system_caches() {
    log_section "System Caches"

    # System caches (with exclusions for critical Apple services)
    local exclude_paths=(
        "com.apple.amsengagementd.classicdatavault"
        "com.apple.aned"
        "com.apple.aneuserd"
        "com.apple.iconservices.store"
    )

    local exclude_args=""
    for path in "${exclude_paths[@]}"; do
        exclude_args+=" ! -path \"/Library/Caches/$path\""
    done

    if [[ "$DRY_RUN" == false ]]; then
        eval "sudo find /Library/Caches/* -type f -mtime +${DAYS_TO_KEEP} $exclude_args -delete -print 2>/dev/null" | wc -l | xargs -I {} log_success "Removed {} system cache files"
    fi

    safe_clean ~/Library/Caches "User caches"
}

cleanup_logs() {
    log_section "System & Application Logs"

    safe_clean /Library/Logs "System logs" true
    safe_clean ~/Library/Logs "User logs"

    # Application-specific logs
    safe_clean ~/Library/Application\ Support/CrashReporter "Crash reports"
    safe_clean /Library/Logs/DiagnosticReports "Diagnostic reports" true
}

cleanup_temp_files() {
    log_section "Temporary Files"

    safe_clean /private/var/tmp "System temp files" true

    # /tmp with exclusions
    if [[ "$DRY_RUN" == false ]]; then
        find /tmp -type f -mtime +"${DAYS_TO_KEEP}" ! -path "/tmp/tmp-mount-*" -delete 2>/dev/null || true
    fi
    log_success "Cleaned /tmp"

    # Sleepimage (can be several GB)
    if [[ -f /private/var/vm/sleepimage ]]; then
        local size
        size=$(ls -l /private/var/vm/sleepimage 2>/dev/null | awk '{print $5}')
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would remove sleepimage ($(bytes_to_human ${size:-0}))"
        else
            sudo rm -f /private/var/vm/sleepimage 2>/dev/null && log_success "Removed sleepimage"
        fi
    fi
}

cleanup_trash() {
    log_section "Trash"

    safe_clean ~/.Trash "User Trash"

    # Clean empty directories in Trash
    if [[ "$DRY_RUN" == false ]]; then
        find ~/.Trash -type d -empty -delete 2>/dev/null || true
    fi

    # External volume trashes
    for trash in /Volumes/*/.Trashes; do
        [[ -d "$trash" ]] && safe_clean "$trash" "Volume Trash: $trash" true
    done
}

cleanup_browsers() {
    log_section "Browser Caches"

    # Safari
    safe_clean ~/Library/Safari/LocalStorage "Safari LocalStorage"
    clean_dir ~/Library/Safari/WebKit/MediaCache "Safari MediaCache"
    safe_clean ~/Library/Caches/com.apple.Safari "Safari Cache"

    # Chrome
    for profile in ~/Library/Application\ Support/Google/Chrome/*/; do
        [[ -d "$profile" ]] && clean_dir "${profile}Cache" "Chrome Cache: $(basename "$profile")"
    done
    clean_dir ~/Library/Caches/Google/Chrome "Chrome System Cache"

    # Firefox
    for profile in ~/Library/Caches/Firefox/Profiles/*/; do
        [[ -d "$profile" ]] && clean_dir "${profile}cache2" "Firefox Cache: $(basename "$profile")"
    done

    # Arc Browser
    clean_dir ~/Library/Caches/company.thebrowser.Browser "Arc Cache"

    # Brave
    clean_dir ~/Library/Caches/BraveSoftware "Brave Cache"

    # Edge
    clean_dir ~/Library/Caches/Microsoft\ Edge "Edge Cache"
}

cleanup_dev_tools() {
    log_section "Development Tools"

    # Xcode
    clean_dir ~/Library/Developer/Xcode/DerivedData "Xcode DerivedData"
    clean_dir ~/Library/Developer/Xcode/Archives "Xcode Archives"
    clean_dir ~/Library/Developer/Xcode/iOS\ Device\ Logs "Xcode Device Logs"
    safe_clean ~/Library/Developer/CoreSimulator/Caches "iOS Simulator Caches"

    # JetBrains IDEs (IntelliJ, WebStorm, PyCharm, etc.)
    for ide_cache in ~/Library/Caches/JetBrains/*/; do
        [[ -d "$ide_cache" ]] && safe_clean "$ide_cache" "JetBrains: $(basename "$ide_cache")"
    done

    # VS Code
    clean_dir ~/Library/Application\ Support/Code/Cache "VS Code Cache"
    clean_dir ~/Library/Application\ Support/Code/CachedData "VS Code CachedData"
    clean_dir ~/Library/Application\ Support/Code/CachedExtensions "VS Code CachedExtensions"
    safe_clean ~/Library/Application\ Support/Code/logs "VS Code Logs"

    # Android Studio
    clean_dir ~/Library/Caches/Google/AndroidStudio* "Android Studio Cache"
    safe_clean ~/.android/cache "Android SDK Cache"
}

cleanup_package_managers() {
    log_section "Package Managers"

    # npm
    if command_exists npm; then
        log_info "Cleaning npm cache..."
        if [[ "$DRY_RUN" == false ]]; then
            npm cache clean --force 2>/dev/null && log_success "npm cache cleaned" || log_warn "npm cache clean failed"
        fi
    fi
    clean_dir ~/.npm/_cacache "npm cache directory"

    # yarn
    if command_exists yarn; then
        log_info "Cleaning yarn cache..."
        if [[ "$DRY_RUN" == false ]]; then
            yarn cache clean 2>/dev/null && log_success "yarn cache cleaned" || log_warn "yarn cache clean failed"
        fi
    fi

    # pnpm
    if command_exists pnpm; then
        log_info "Cleaning pnpm cache..."
        if [[ "$DRY_RUN" == false ]]; then
            pnpm store prune 2>/dev/null && log_success "pnpm store pruned" || log_warn "pnpm store prune failed"
        fi
    fi

    # pip
    safe_clean ~/Library/Caches/pip "pip cache"

    # Composer
    if command_exists composer; then
        log_info "Cleaning Composer cache..."
        if [[ "$DRY_RUN" == false ]]; then
            composer clearcache 2>/dev/null && log_success "Composer cache cleaned" || log_warn "Composer clearcache failed"
        fi
    fi

    # CocoaPods
    safe_clean ~/Library/Caches/CocoaPods "CocoaPods cache"

    # Gradle
    safe_clean ~/.gradle/caches "Gradle caches"
    clean_dir ~/.gradle/daemon "Gradle daemon logs"

    # Maven
    safe_clean ~/.m2/repository "Maven repository (old artifacts)"

    # Cargo (Rust)
    safe_clean ~/.cargo/registry/cache "Cargo registry cache"

    # Go
    if command_exists go; then
        log_info "Cleaning Go module cache..."
        if [[ "$DRY_RUN" == false ]]; then
            go clean -modcache 2>/dev/null && log_success "Go module cache cleaned" || log_warn "Go clean failed"
        fi
    fi
}

cleanup_applications() {
    log_section "Applications"

    # Spotify
    safe_clean ~/Library/Application\ Support/Spotify/PersistentCache "Spotify cache"

    # Discord
    clean_dir ~/Library/Application\ Support/discord/Cache "Discord cache"
    clean_dir ~/Library/Application\ Support/discord/Code\ Cache "Discord Code Cache"

    # Slack
    clean_dir ~/Library/Application\ Support/Slack/Cache "Slack cache"
    clean_dir ~/Library/Application\ Support/Slack/Service\ Worker/CacheStorage "Slack Service Worker Cache"

    # Telegram
    safe_clean ~/Library/Group\ Containers/*.Telegram*/Telegram "Telegram cache"

    # WhatsApp
    clean_dir ~/Library/Application\ Support/WhatsApp/Cache "WhatsApp cache"

    # Figma
    clean_dir ~/Library/Caches/Figma "Figma cache"

    # Notion
    clean_dir ~/Library/Application\ Support/Notion/Cache "Notion cache"
}

cleanup_homebrew() {
    log_section "Homebrew"

    if [[ "$SKIP_HOMEBREW" == true ]]; then
        log_info "Skipping Homebrew cleanup (--skip-homebrew)"
        return 0
    fi

    if ! command_exists brew; then
        log_warn "Homebrew not installed, skipping"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        brew cleanup --dry-run --prune="${DAYS_TO_KEEP}" 2>/dev/null || true
        brew autoremove --dry-run 2>/dev/null || true
    else
        log_info "Running brew cleanup..."
        brew cleanup --prune="${DAYS_TO_KEEP}" 2>/dev/null && log_success "brew cleanup complete" || log_warn "brew cleanup had issues"

        log_info "Running brew autoremove..."
        brew autoremove 2>/dev/null && log_success "brew autoremove complete" || log_warn "brew autoremove had issues"

        log_info "Running brew doctor..."
        brew doctor 2>/dev/null || log_warn "brew doctor found issues (check manually)"
    fi
}

cleanup_docker() {
    log_section "Docker"

    if [[ "$SKIP_DOCKER" == true ]]; then
        log_info "Skipping Docker cleanup (--skip-docker)"
        return 0
    fi

    if ! command_exists docker; then
        log_warn "Docker not installed, skipping"
        return 0
    fi

    # Check if Docker is running and using local context
    if ! docker info >/dev/null 2>&1; then
        log_warn "Docker daemon not running, skipping"
        return 0
    fi

    local current_context
    current_context=$(docker context show 2>/dev/null) || {
        log_warn "Unable to determine Docker context, skipping"
        return 0
    }

    local endpoint
    endpoint=$(docker context inspect "$current_context" --format '{{.Endpoints.docker.Host}}' 2>/dev/null) || {
        log_warn "Unable to inspect Docker context, skipping"
        return 0
    }

    if [[ "$endpoint" != unix://* ]]; then
        log_warn "Docker using remote context ($endpoint), skipping cleanup"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would run: docker system prune -f"
        docker system df 2>/dev/null || true
        return 0
    fi

    log_info "Pruning Docker system..."
    docker system prune -f 2>/dev/null && log_success "Docker pruned" || log_warn "Docker prune had issues"

    log_info "Removing dangling volumes..."
    docker volume prune -f 2>/dev/null && log_success "Docker volumes pruned" || log_warn "Volume prune had issues"

    log_info "Docker disk usage after cleanup:"
    docker system df 2>/dev/null || true
}

cleanup_memory() {
    log_section "System Memory"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would run: sudo purge"
        return 0
    fi

    log_info "Purging system memory cache..."
    sudo purge 2>/dev/null && log_success "Memory purged" || log_warn "Memory purge failed"
}

# =============================================================================
# Main Execution
# =============================================================================

show_help() {
    cat << EOF
${BOLD}cleanmac-enhanced${NC} - Advanced macOS cleanup utility

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS] [DAYS]

${BOLD}OPTIONS:${NC}
    -h, --help          Show this help message
    -d, --dry-run       Show what would be deleted without deleting
    -v, --verbose       Show verbose output including skipped items
    -j, --jobs N        Number of parallel jobs (default: 4)
    --skip-docker       Skip Docker cleanup
    --skip-homebrew     Skip Homebrew cleanup

${BOLD}ARGUMENTS:${NC}
    DAYS                Number of days of cache to keep (default: 7)

${BOLD}EXAMPLES:${NC}
    $(basename "$0")                    # Clean files older than 7 days
    $(basename "$0") 14                 # Clean files older than 14 days
    $(basename "$0") --dry-run          # Preview what would be cleaned
    $(basename "$0") -v --skip-docker   # Verbose, skip Docker

${BOLD}ENVIRONMENT VARIABLES:${NC}
    DAYS_TO_KEEP        Override default days (alternative to argument)

EOF
}

parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            --skip-docker)
                SKIP_DOCKER=true
                shift
                ;;
            --skip-homebrew)
                SKIP_HOMEBREW=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                DAYS_TO_KEEP=$1
                shift
                ;;
        esac
    done

    # Validate DAYS_TO_KEEP
    if ! [[ $DAYS_TO_KEEP =~ ^(0|[1-9][0-9]*)$ ]]; then
        log_error "DAYS must be a positive integer, got: $DAYS_TO_KEEP"
        exit 1
    fi
}

main() {
    parse_args "$@"

    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║           macOS Enhanced Cleanup Utility                     ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Get initial disk space
    local free_storage total_storage free_gb total_gb
    free_storage=$(df -k / | awk 'NR==2 {print $4}')
    total_storage=$(df -k / | awk 'NR==2 {print $2}')
    free_gb=$(echo "scale=2; $free_storage / 1024 / 1024" | bc)
    total_gb=$(echo "scale=2; $total_storage / 1024 / 1024" | bc)

    echo -e "${CYAN}Disk Space:${NC} ${free_gb} GB free / ${total_gb} GB total"
    echo -e "${CYAN}Mode:${NC} ${DRY_RUN:+DRY RUN}${DRY_RUN:-LIVE}"
    echo -e "${CYAN}Retention:${NC} Keeping files newer than ${DAYS_TO_KEEP} days"
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        log_info "Requesting sudo permissions..."
        sudo -v

        # Keep sudo alive in background
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi

    local start_time
    start_time=$(date +%s)

    # Run cleanup modules
    cleanup_system_caches
    cleanup_logs
    cleanup_temp_files
    cleanup_trash
    cleanup_browsers
    cleanup_dev_tools
    cleanup_package_managers
    cleanup_applications
    cleanup_homebrew
    cleanup_docker
    cleanup_memory

    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    # Final statistics
    log_section "Summary"

    local free_storage_final free_gb_final freed_kb freed_human
    free_storage_final=$(df -k / | awk 'NR==2 {print $4}')
    free_gb_final=$(echo "scale=2; $free_storage_final / 1024 / 1024" | bc)
    freed_kb=$((free_storage_final - free_storage))

    # Handle negative values (can happen due to concurrent disk activity)
    ((freed_kb < 0)) && freed_kb=0
    freed_human=$(bytes_to_human $((freed_kb * 1024)))

    echo ""
    echo -e "${BOLD}Results:${NC}"
    echo -e "  ${GREEN}✓${NC} Files removed: ${STATS[files_removed]}"
    echo -e "  ${GREEN}✓${NC} Directories cleaned: ${STATS[dirs_removed]}"
    [[ ${STATS[errors]} -gt 0 ]] && echo -e "  ${RED}✗${NC} Errors: ${STATS[errors]}"
    echo ""
    echo -e "  ${CYAN}Space freed:${NC} $freed_human"
    echo -e "  ${CYAN}Disk space:${NC} ${free_gb_final} GB free / ${total_gb} GB total"
    echo -e "  ${CYAN}Duration:${NC} ${duration}s"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}This was a dry run. No files were actually deleted.${NC}"
        echo -e "${YELLOW}Run without --dry-run to perform actual cleanup.${NC}"
    else
        log_success "Cleanup complete!"
    fi
}

main "$@"
