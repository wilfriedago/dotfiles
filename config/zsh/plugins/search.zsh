# =============================================================================================
# ~/.config/zsh/plugins/search.zsh
# =============================================================================================
# Enhanced Search Zsh Plugin
# This plugin provides powerful search capabilities with !bangs, multiple engines, and more.
#
# Features:
# - DuckDuckGo !bang support
# - Multiple search engines
# - URL encoding
# - Search history
# - Custom search shortcuts
# - Direct browser integration
#
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Configuration
SEARCH_HISTORY_FILE="$ZSH_DATA_HOME/search_history"
SEARCH_DEFAULT_ENGINE="duckduckgo"
SEARCH_BROWSER="${BROWSER:-open}"

# Ensure search history directory exists
[[ ! -d "$(dirname "$SEARCH_HISTORY_FILE")" ]] && mkdir -p "$(dirname "$SEARCH_HISTORY_FILE")"

# Browser aliases
alias chromium="/Applications/Chromium.app/Contents/MacOS/Chromium"
alias safari="/Applications/Safari.app/Contents/MacOS/Safari"
alias firefox="/Applications/Firefox.app/Contents/MacOS/firefox"

# URL encoding function
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * ) printf -v o '%%%02x' "'$c" ;;
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

# Add to search history
_add_search_history() {
    local query="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $query" >> "$SEARCH_HISTORY_FILE"
}

# Search engines configuration
declare -A SEARCH_ENGINES=(
    [duckduckgo]="https://duckduckgo.com/?q="
    [ddg]="https://duckduckgo.com/?q="
    [google]="https://www.google.com/search?q="
    [g]="https://www.google.com/search?q="
    [bing]="https://www.bing.com/search?q="
    [yahoo]="https://search.yahoo.com/search?p="
    [yandex]="https://yandex.com/search/?text="
    [startpage]="https://www.startpage.com/sp/search?query="
    [searx]="https://searx.be/search?q="
    [brave]="https://search.brave.com/search?q="
)

# Specialized search shortcuts
declare -A SEARCH_SHORTCUTS=(
    # Development
    [gh]="https://github.com/search?q="
    [so]="https://stackoverflow.com/search?q="
    [mdn]="https://developer.mozilla.org/en-US/search?q="
    [npm]="https://www.npmjs.com/search?q="
    [pypi]="https://pypi.org/search/?q="
    [docker]="https://hub.docker.com/search?q="
    [rust]="https://crates.io/search?q="

    # Documentation
    [wiki]="https://en.wikipedia.org/wiki/Special:Search?search="
    [arch]="https://wiki.archlinux.org/index.php?search="
    [man]="https://man7.org/linux/man-pages/dir_by_project.html#man-pages"

    # Media & Entertainment
    [yt]="https://www.youtube.com/results?search_query="
    [imdb]="https://www.imdb.com/find?q="
    [spotify]="https://open.spotify.com/search/"
    [twitch]="https://www.twitch.tv/search?term="

    # Shopping & Reviews
    [amazon]="https://www.amazon.com/s?k="
    [ebay]="https://www.ebay.com/sch/i.html?_nkw="
    [aliexpress]="https://www.aliexpress.com/wholesale?SearchText="

    # News & Social
    [reddit]="https://www.reddit.com/search/?q="
    [twitter]="https://twitter.com/search?q="
    [hackernews]="https://hn.algolia.com/?q="
    [lobsters]="https://lobste.rs/search?q="

    # Academic & Research
    [scholar]="https://scholar.google.com/scholar?q="
    [arxiv]="https://arxiv.org/search/?query="
    [pubmed]="https://pubmed.ncbi.nlm.nih.gov/?term="

    # Maps & Travel
    [maps]="https://www.google.com/maps/search/"
    [openstreetmap]="https://www.openstreetmap.org/search?query="
    [booking]="https://www.booking.com/searchresults.html?ss="

    # Images & Design
    [images]="https://www.google.com/search?tbm=isch&q="
    [unsplash]="https://unsplash.com/s/photos/"
    [dribbble]="https://dribbble.com/search?q="
    [behance]="https://www.behance.net/search/projects?search="
)

# Main search function
search() {
    local query=""
    local engine="$SEARCH_DEFAULT_ENGINE"
    local browser="$SEARCH_BROWSER"
    local use_bang=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--engine)
                engine="$2"
                shift 2
                ;;
            -b|--browser)
                browser="$2"
                shift 2
                ;;
            -l|--list)
                _search_list_engines
                return 0
                ;;
            -h|--history)
                _search_show_history
                return 0
                ;;
            --clear-history)
                _search_clear_history
                return 0
                ;;
            --help)
                _search_help
                return 0
                ;;
            -*)
                echo "Unknown option: $1"
                _search_help
                return 1
                ;;
            *)
                query+="$1 "
                shift
                ;;
        esac
    done

    # Remove trailing space
    query="${query% }"

    if [[ -z "$query" ]]; then
        echo "Usage: search [options] <query>"
        echo "Use 'search --help' for more information."
        return 1
    fi

    # Check for !bang syntax or shortcut
    local url=""
    if [[ "$query" =~ ^!([a-zA-Z0-9]+)[[:space:]]+(.+)$ ]]; then
        # DuckDuckGo !bang - let DuckDuckGo handle it
        local bang="${match[1]}"
        local search_terms="${match[2]}"
        url="https://duckduckgo.com/?q=%21${bang}+$(urlencode "$search_terms")"
        use_bang=true
    elif [[ "$query" =~ ^([a-zA-Z0-9]+):[[:space:]]*(.+)$ ]]; then
        # Custom shortcut syntax (e.g., "gh: my query")
        local shortcut="${match[1]}"
        local search_terms="${match[2]}"

        if [[ -n "${SEARCH_SHORTCUTS[$shortcut]}" ]]; then
            url="${SEARCH_SHORTCUTS[$shortcut]}$(urlencode "$search_terms")"
        else
            echo "Unknown search shortcut: $shortcut"
            echo "Use 'search -l' to see available shortcuts."
            return 1
        fi
    else
        # Regular search with specified engine
        if [[ -n "${SEARCH_ENGINES[$engine]}" ]]; then
            url="${SEARCH_ENGINES[$engine]}$(urlencode "$query")"
        elif [[ -n "${SEARCH_SHORTCUTS[$engine]}" ]]; then
            url="${SEARCH_SHORTCUTS[$engine]}$(urlencode "$query")"
        else
            echo "Unknown search engine: $engine"
            echo "Use 'search -l' to see available engines."
            return 1
        fi
    fi

    # Add to history
    _add_search_history "$query"

    # Open in browser
    case "$browser" in
        chromium)
            /Applications/Chromium.app/Contents/MacOS/Chromium "$url" &
            ;;
        safari)
            /Applications/Safari.app/Contents/MacOS/Safari "$url" &
            ;;
        firefox)
            /Applications/Firefox.app/Contents/MacOS/firefox "$url" &
            ;;
        *)
            $browser "$url"
            ;;
    esac

    echo "Searching for: $query"
    [[ "$use_bang" == true ]] && echo "Using DuckDuckGo !bang"
}

# List available engines and shortcuts
_search_list_engines() {
    echo "Available Search Engines:"
    printf "%-15s %s\n" "Alias" "URL"
    printf "%-15s %s\n" "-----" "---"
    for engine in "${(@k)SEARCH_ENGINES}"; do
        printf "%-15s %s\n" "$engine" "${SEARCH_ENGINES[$engine]}"
    done

    echo -e "\nAvailable Shortcuts:"
    printf "%-15s %s\n" "Shortcut" "URL"
    printf "%-15s %s\n" "--------" "---"
    for shortcut in "${(@ok)SEARCH_SHORTCUTS}"; do
        printf "%-15s %s\n" "$shortcut" "${SEARCH_SHORTCUTS[$shortcut]}"
    done

    echo -e "\nUsage Examples:"
    echo "  search hello world                    # Default engine"
    echo "  search -e google hello world          # Specific engine"
    echo "  search !w Albert Einstein             # DuckDuckGo !bang for Wikipedia"
    echo "  search gh: zsh plugins                # GitHub shortcut"
    echo "  search yt: funny cats                 # YouTube shortcut"
}

# Show search history
_search_show_history() {
    if [[ -f "$SEARCH_HISTORY_FILE" ]]; then
        echo "Search History (last 20 searches):"
        echo "=================================="
        tail -n 20 "$SEARCH_HISTORY_FILE"
    else
        echo "No search history found."
    fi
}

# Clear search history
_search_clear_history() {
    if [[ -f "$SEARCH_HISTORY_FILE" ]]; then
        > "$SEARCH_HISTORY_FILE"
        echo "Search history cleared."
    else
        echo "No search history to clear."
    fi
}

# Help function
_search_help() {
    cat << 'EOF'
Enhanced Search Plugin - Command Line Search Tool

USAGE:
    search [OPTIONS] <query>

OPTIONS:
    -e, --engine <engine>     Use specific search engine
    -b, --browser <browser>   Use specific browser
    -l, --list               List available engines and shortcuts
    -h, --history            Show search history
    --clear-history          Clear search history
    --help                   Show this help message

SEARCH SYNTAX:
    Regular search:          search hello world
    Engine selection:        search -e google hello world
    DuckDuckGo !bangs:       search !w Albert Einstein
    Shortcuts:               search gh: zsh plugins
                             search yt: funny cats
                             search so: javascript async

POPULAR !BANGS:
    !w          Wikipedia
    !g          Google
    !gi         Google Images
    !yt         YouTube
    !r          Reddit
    !gh         GitHub
    !so         Stack Overflow
    !mdn        MDN Web Docs
    !npm        NPM
    !pypi       PyPI

EXAMPLES:
    search hello world
    search -e google "machine learning"
    search !w "quantum computing"
    search gh: "awesome zsh plugins"
    search yt: "zsh tutorial"
    search so: "javascript promises"
    search -b firefox "web development"

For a full list of available engines and shortcuts, use: search -l
EOF
}

# Quick aliases for common searches
alias s="search"
alias sg="search -e google"
alias sgh="search gh:"
alias syt="search yt:"
alias sso="search so:"
alias swiki="search !w"
alias simages="search images:"

# Auto-completion for search engines and shortcuts
_search_completion() {
    local context state line
    local -a engines shortcuts

    # Get available engines and shortcuts
    engines=(${(k)SEARCH_ENGINES})
    shortcuts=(${(k)SEARCH_SHORTCUTS})

    _arguments \
        '(-e --engine)'{-e,--engine}'[Search engine]:engine:($engines $shortcuts)' \
        '(-b --browser)'{-b,--browser}'[Browser]:browser:(chromium safari firefox open)' \
        '(-l --list)'{-l,--list}'[List engines and shortcuts]' \
        '(-h --history)'{-h,--history}'[Show search history]' \
        '--clear-history[Clear search history]' \
        '--help[Show help]' \
        '*:search query:'
}

# Register completion
compdef _search_completion search s
