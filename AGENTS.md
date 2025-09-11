# AI Agents Instructions

This repository contains Wilfried's personal dotfiles and system configuration for macOS, managed using `dotdrop`. Understanding the dotdrop configuration system is essential for working effectively in this codebase.

## Architecture Overview

### Dotdrop Configuration System
- **Core file**: `dotdrop.config.yml` - defines profiles, dotfiles mappings, and installation rules
- **Two profiles**: `default` (core tools) and `macos` (VSCode-specific configurations)
- **Naming convention**: `d_*` for directories, `f_*` for files in dotdrop config
- **Source location**: All configs live in `config/` directory, deployed to appropriate system locations

### Directory Structure
```
config/           # Source configurations
├── zsh/         # Shell configuration (modular: aliases, functions, completions)
├── vscode/      # VSCode settings, keybindings, extensions, custom CSS/JS
├── aerospace/   # Tiling window manager config
├── nvim/        # Neovim configuration
└── [tool]/      # Individual tool configurations
scripts/         # Setup and maintenance scripts
Brewfile         # Homebrew package definitions
```

## Key Workflows

### Configuration Management
- **Deploy configs**: `dotdrop install -c dotdrop.config.yaml -p default --force`
- **macOS-specific**: `dotdrop install -c dotdrop.config.yaml -p macos --force`
- **VSCode locations**: Custom files go to `~/Library/Application Support/Code/User/`
- **Extensions**: Use `code --install-extension` or update `extensions.json`

### Homebrew Management
- **Install apps**: `brew bundle --global --file ~/.Brewfile`
- **Categories**: Organized by Apps, CLI tools, Fonts, QuickLook plugins
- **Taps**: Custom repositories for specialized tools (koekeishiya, tufin, etc.)

### Shell Configuration
- **Modular Zsh**: Separate files for aliases, functions, completions
- **Plugin manager**: Zinit for Zsh plugins
- **Prompt**: Starship configured via `config/starship/starship.toml`

## Project-Specific Patterns

### Dotdrop File Mappings
When adding new configurations:
1. Place source in `config/[tool]/`
2. Add to `dotdrop.config.yml` under appropriate profile
3. Use `d_toolname` for directories, `f_toolname` for files
4. Specify correct `dst` path for system deployment

### VSCode Customization
- **UI modifications**: `custom.css` and `custom.js` for interface tweaks
- **Fonts**: BlexMono Nerd Font is preferred, with JetBrainsMono fallback
- **Extensions**: Managed via `extensions.json`, not manual installation
- **Profiles**: Separate work contexts with different settings

### Tool Configuration Philosophy
- **Minimalist approach**: Only daily-use tools in Brewfile
- **Performance focus**: Modern alternatives (eza vs ls, bat vs cat, zoxide vs cd)
- **Vim motions**: Karabiner-Elements for system-wide vi-like navigation
- **Tiling WM**: AeroSpace for window management without SIP disabling

## Integration Points

### macOS System Integration
- **Defaults**: `scripts/macos/default.sh` for system preferences
- **Hotkeys**: skhd for keyboard shortcuts, integrated with AeroSpace
- **Security**: GPG configuration for commit signing
- **SSH**: Centralized SSH config in `config/ssh.conf`

### Development Environment
- **Terminal**: Ghostty as primary terminal emulator
- **File management**: Yazi for terminal file browsing
- **Git**: Enhanced with lazygit, git-delta, and git-cliff for changelogs
- **Kubernetes**: k9s for cluster management, integrated with helm configs

## Common Tasks

### Adding New Tool Configuration
1. Create `config/[tool]/` directory with configuration files
2. Add `d_tool` or `f_tool` entry to `dotdrop.config.yml`
3. Specify source (`src`) and destination (`dst`) paths
4. Add to appropriate profile (`default` or `macos`)
5. Test with `dotdrop install -c dotdrop.config.yaml -p [profile] --dry`

### Updating Homebrew Packages
- Add to appropriate section in `Brewfile` (maintain alphabetical order)
- Categories: Apps (cask), CLI tools (brew), Fonts, QuickLook plugins
- Include comments for non-obvious packages

### Shell Modifications
- **Aliases**: Add to `config/zsh/aliases.zsh`
- **Functions**: Add to `config/zsh/functions.zsh`
- **Completions**: Add to `config/zsh/completions/` directory
- **Plugins**: Modify plugin loading in `config/zsh/zshrc`

Always test dotdrop deployments with `--dry` flag before applying changes to avoid system configuration conflicts.
