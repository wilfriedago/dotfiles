# NixOS Package Equivalents for Brewfile
# This file documents the NixOS package equivalents for the macOS Brewfile
# These packages are defined in the flake.nix and home.nix files

# =============================================================================================
# Core System Packages (defined in configuration.nix)
# =============================================================================================

# Essential tools
git                 # Version control system
curl                # Command-line tool for transferring data
wget                # Network utility to retrieve files from the web
vim                 # Text editor
neovim              # Modern vim fork
tmux                # Terminal multiplexer

# Development tools  
gcc                 # GNU compiler collection
gnumake             # Build automation tool

# Terminal tools
zsh                 # Z shell
starship            # Cross-shell prompt

# File management
unzip               # Extraction utility for ZIP archives
p7zip               # File archiver with high compression ratio

# Network tools
nmap                # Network exploration tool and security scanner

# System monitoring
btop                # System monitor (equivalent to btop in Brewfile)
fastfetch           # System information tool (equivalent to fastfetch)

# =============================================================================================
# User Packages (defined in home.nix)
# =============================================================================================

# Development tools
gh                  # GitHub CLI (equivalent to brew 'gh')
glab                # GitLab CLI (equivalent to brew 'glab')
git-delta           # Better git diff (equivalent to brew 'git-delta')
lazygit             # Terminal UI for git (equivalent to brew 'lazygit')
lazydocker          # Terminal UI for docker (equivalent to brew 'lazydocker')

# Terminal utilities
eza                 # Modern ls replacement (equivalent to brew 'eza')
fd                  # Better find (equivalent to brew 'fd')
fzf                 # Fuzzy finder (equivalent to brew 'fzf')
ripgrep             # Better grep (equivalent to brew 'ripgrep')
bat                 # Better cat (equivalent to brew 'bat')
yazi                # Terminal file manager (equivalent to brew 'yazi')
zoxide              # Smart cd (equivalent to brew 'zoxide')
jq                  # JSON processor (equivalent to brew 'jq')

# Network tools
xh                  # Better curl (equivalent to brew 'xh')

# Development environments
nodejs              # Node.js runtime
python3             # Python interpreter

# Kubernetes tools
kubectl             # Kubernetes CLI (equivalent to brew 'kubernetes-cli')
k9s                 # Kubernetes dashboard (equivalent to brew 'k9s')

# Infrastructure tools
terraform           # Infrastructure as code (equivalent to brew 'hashicorp/tap/terraform')
vault               # Secrets management (equivalent to brew 'hashicorp/tap/vault')

# Text editors
neovim              # Modern vim (equivalent to brew 'neovim')

# Fonts
nerdfonts           # Nerd fonts collection (equivalent to cask 'font-symbols-nerd-font')

# GUI applications
discord             # Voice and text chat (equivalent to cask 'discord')
spotify             # Music streaming (equivalent to cask 'spotify')
bitwarden           # Password manager (equivalent to cask 'bitwarden')
obsidian            # Knowledge base (equivalent to cask 'obsidian')
vscode              # Code editor (equivalent to cask 'visual-studio-code')

# =============================================================================================
# Window Manager (replaces AeroSpace)
# =============================================================================================

# i3wm                # X11 tiling window manager (alternative to AeroSpace)
# sway                # Wayland tiling window manager (alternative to AeroSpace)

# =============================================================================================
# Packages Not Available or Not Needed on NixOS
# =============================================================================================

# pinentry-mac        # macOS-specific, replaced by pinentry-gtk or pinentry-qt
# skhd                # macOS-specific hotkey daemon, replaced by i3/sway bindings
# lporg               # macOS-specific Launchpad organizer, not needed on Linux
# alt-tab             # macOS-specific, not needed with proper window manager
# gitkraken           # Available as flatpak or AppImage if needed
# jetbrains-toolbox   # Available as flatpak or direct download
# basictex            # Replaced by texlive packages in NixOS

# =============================================================================================
# Additional NixOS-Specific Tools
# =============================================================================================

# rofi                # Application launcher for i3/sway
# i3status            # Status bar for i3
# waybar              # Status bar for sway
# picom               # Compositor for X11
# swaybg              # Wallpaper tool for sway
# nm-applet           # Network manager applet
# blueman-applet      # Bluetooth applet

# =============================================================================================
# Package Management Notes
# =============================================================================================

# Unlike macOS Homebrew, NixOS uses:
# 1. System packages defined in configuration.nix
# 2. User packages defined in home.nix (via Home Manager)
# 3. Temporary packages via `nix shell`
# 4. Development environments via `nix develop` or direnv
# 5. Flatpak for some GUI applications
# 6. AppImages for some proprietary software

# To add new packages:
# - System packages: Add to environment.systemPackages in configuration.nix
# - User packages: Add to home.packages in home.nix
# - Development tools: Create a shell.nix or flake.nix in project directory