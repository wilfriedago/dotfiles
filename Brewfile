# Curated macOS workstation packages.
cask_args appdir: '~/Applications', require_sha: true

# Taps
tap 'derailed/k9s'          # k9s Kubernetes TUI releases
tap 'haseebkhalid1507/tap'  # myx shell utility
tap 'hashicorp/tap'         # Terraform and other HashiCorp tools
tap 'localstack/tap'        # LocalStack AWS emulator CLI
tap 'nikitabobko/tap'       # AeroSpace tiling window manager
tap 'quarkusio/tap'         # Quarkus Java framework CLI
tap 'stablyai/orca'         # Orca agent workspace app

# Applications
cask 'aerospace'           # i3-like tiling window manager for macOS
cask 'alt-tab'             # Windows-style alt-tab window switcher
cask 'bluestacks'          # Android emulator for app testing
# Both desktop apps bundle their own agent CLI and keep it updated with the app;
# plugins/claude.zsh and plugins/codex.zsh put those on $PATH. The standalone
# 'claude-code@latest' and 'codex' casks are intentionally not installed — a second
# copy of the same CLI updates on its own schedule and drifts from the app's.
cask 'chatgpt'             # OpenAI ChatGPT desktop client (ships the codex CLI)
cask 'claude'              # Anthropic Claude desktop client (ships the claude CLI)
cask 'copilot-cli'         # GitHub Copilot command-line agent
cask 'discord'             # Chat and voice for communities
cask 'ghostty'             # GPU-accelerated terminal emulator
cask 'gitkraken'           # Visual Git client
cask 'google-chrome'       # Chrome browser for web development
cask 'granola'             # AI meeting notetaker
cask 'helium-browser'      # Privacy-focused Chromium browser
cask 'iina'                # Modern macOS media player
cask 'jetbrains-toolbox'   # Manages JetBrains IDE installs
cask 'linear'              # Issue tracking and project planning
cask 'megasync'            # MEGA cloud storage sync client
cask 'obsidian'            # Markdown knowledge base
cask 'orbstack'            # Fast Docker and Linux VMs for macOS
cask 'pearcleaner'         # App uninstaller and leftover cleaner
cask 'postman'             # API request builder and testing
cask 'raycast'             # Launcher, clipboard history, and window commands
cask 'signal'              # End-to-end encrypted messaging
cask 'slack'               # Team chat and collaboration
cask 'stablyai/orca/orca'  # Orca parallel agent workspaces
cask 'transmission'        # Lightweight BitTorrent client
cask 'visual-studio-code'  # Primary code editor
cask 'zotero'              # Reference and citation manager

# Command-line tools
brew 'bat'                            # cat with syntax highlighting and paging
brew 'bison'                          # GNU parser generator, newer than macOS build
brew 'btop'                           # Resource monitor TUI
brew 'carapace'                       # Completion specs for CLIs zsh has none for
brew 'cmake'                          # Cross-platform build system generator
brew 'cocoapods'                      # Dependency manager for iOS/macOS projects
brew 'composer'                       # PHP dependency manager
brew 'coreutils'                      # GNU core utilities (gls, gdate, ...)
brew 'difftastic'                     # Structural diff — backs `git dft`
brew 'dotdrop'                        # Dotfile manager driving this repository
brew 'eas-cli'                        # Expo Application Services build CLI
brew 'eza'                            # Modern ls replacement
brew 'fastfetch'                      # System information banner
brew 'fd'                             # Fast, user-friendly find replacement
brew 'ffmpeg'                         # Audio and video transcoding
brew 'ffuf'                           # Fast web fuzzer for security testing
brew 'flawfinder'                     # Static analysis for C/C++ security flaws
brew 'fzf'                            # Fuzzy finder for shell and editor
brew 'gawk'                           # GNU awk, superset of macOS awk
brew 'gh'                             # GitHub CLI
brew 'git-cliff'                      # Changelog generator from conventional commits
brew 'git-filter-repo'                # Rewrite Git history safely
brew 'git-lfs'                        # Git extension for large files
brew 'gitleaks'                       # Scans repositories for leaked secrets
brew 'glab'                           # GitLab CLI
brew 'gnu-sed'                        # GNU sed, avoids BSD sed incompatibilities
brew 'gradle-completion'              # Shell completion for Gradle
brew 'grep'                           # GNU grep, superset of macOS grep
brew 'helm'                           # Kubernetes package manager
brew 'jq'                             # JSON processor — used by the `kj` kubectl alias
brew 'just'                           # Command runner used by this repository
brew 'derailed/k9s/k9s'               # Kubernetes cluster TUI
brew 'kubernetes-cli'                 # kubectl Kubernetes client
brew 'lizard-analyzer'                # Code complexity analyzer
brew 'localstack/tap/localstack-cli'  # Runs AWS services locally
brew 'mariadb-connector-c'            # MariaDB C client library
brew 'mas'                            # Mac App Store CLI
brew 'mise'                           # Polyglot runtime and tool version manager
brew 'mkcert'                         # Locally trusted development certificates
brew 'haseebkhalid1507/tap/myx'       # Shell workflow helper
brew 'neovim'                         # Terminal editor
brew 'nmap'                           # Network and port scanner
brew 'pandoc'                         # Universal document converter
brew 'pkgconf'                        # pkg-config implementation for builds
brew 'poppler'                        # PDF utilities (pdftotext, pdfimages)
brew 'quarkusio/tap/quarkus'          # Quarkus Java project CLI
brew 'ripgrep'                        # Fast recursive code search
brew 'rtk'                            # Compresses noisy command output
brew 'shellcheck'                     # Shell script linter
brew 'starship'                       # Cross-shell prompt
brew 'telnet'                         # Plain TCP connectivity checks
brew 'hashicorp/tap/terraform'        # Infrastructure as code
brew 'tmux'                           # Terminal multiplexer
brew 'trash'                          # Move files to macOS Trash — backs the `del` alias
brew 'tree-sitter-cli'                # Builds and tests Tree-sitter grammars
brew 'typst'                          # Modern typesetting system
brew 'unar'                           # Extracts RAR and other archive formats
brew 'uv'                             # Fast Python package and project manager
brew 'viu'                            # Image viewer for the terminal
brew 'watchman'                       # File watching service for React Native
brew 'wget'                           # Non-interactive file downloader
brew 'witr'                           # Terminal workflow helper
brew 'yazi'                           # Terminal file manager
brew 'yq'                             # YAML/JSON processor
brew 'yt-dlp'                         # Video and audio downloader
brew 'zoxide'                         # Frecency-based directory jumping

# VS Code extensions
vscode 'anthropic.claude-code'         # Claude Code IDE integration
vscode 'openai.chatgpt'                # ChatGPT/Codex IDE integration
vscode 'pkief.material-icon-theme'     # Material file icons
vscode 'pkief.material-product-icons'  # Material UI icons
vscode 'subframe7536.custom-ui-style'  # Custom window and font styling

# Mac App Store
mas 'bitwarden', id: 1352778147      # Password manager
mas 'keynote', id: 361285480         # Apple presentations
mas 'microsoft-word', id: 462054704  # Microsoft word processor
mas 'numbers', id: 361304891         # Apple spreadsheets
mas 'pages', id: 361309726           # Apple word processor
mas 'reeder', id: 6475002485         # RSS and read-later client
mas 'telegram', id: 747648890        # Messaging
mas 'termius', id: 1176074088        # SSH client with synced hosts
mas 'whatsapp', id: 310633997        # Messaging
