# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS using [dotdrop](https://github.com/deadc0de6/dotdrop) for managing configuration files. The repository automates environment setup, maintains consistent configurations across machines, and provides a modular shell configuration system.

## Common Commands

### Dotfiles Management

```sh
# Deploy dotfiles to a new system
dotdrop install -c dotdrop.config.yaml -p default --force
dotdrop install -c dotdrop.config.yaml -p macos --force

# Update dotfiles after making changes
dotdrop update
```

### Package Management

```sh
# Install/update all packages and applications
brew bundle --global --file $HOME/.Brewfile

# Install specific categories from Brewfile
brew bundle --file Brewfile
```

### macOS Settings

```sh
# Apply macOS system settings
bash ~/.scripts/macos/settings.sh
```

## Architecture

### Dotdrop Configuration

The repository uses [dotdrop.config.yml](dotdrop.config.yml) to define:
- **Profiles**: `default` (cross-platform configs) and `macos` (macOS-specific configs like VSCode settings)
- **Dotfiles mapping**: Source files in `config/` are deployed to their respective system locations (e.g., `config/zsh/zshrc` → `~/.zshrc`)

### Shell Configuration (Zsh)

Shell configuration is modular and located in [config/zsh/](config/zsh/):

- **[zshrc](config/zsh/zshrc)**: Main entry point that loads Zinit plugin manager and sources other modules
- **[aliases.zsh](config/zsh/aliases.zsh)**: Command aliases
- **[functions.zsh](config/zsh/functions.zsh)**: Custom shell functions
- **[settings.zsh](config/zsh/settings.zsh)**: Shell options and configuration
- **[completions.zsh](config/zsh/completions.zsh)**: Completion system setup
- **[plugins/](config/zsh/plugins/)**: Tool-specific plugins with aliases and completions

#### Zsh Plugin Pattern

Each plugin in `config/zsh/plugins/` follows a consistent structure:
1. Check if the tool is installed (`if (( ! $+commands[tool] )); then return; fi`)
2. Define aliases for common operations
3. Set up completions using the tool's native completion generator
4. Cache completions in `$ZSH_CACHE_DIR/completions/`

Example plugins: [kubectl.zsh](config/zsh/plugins/kubectl.zsh), [kind.zsh](config/zsh/plugins/kind.zsh), [docker.zsh](config/zsh/plugins/docker.zsh)

### Package Management (Brewfile)

[Brewfile](Brewfile) contains all macOS packages organized by category:
- **Taps**: Third-party Homebrew repositories
- **Apps**: GUI applications (cask)
- **CLI tools**: Command-line utilities (brew)
- **Linters/formatters**: Development tools
- **VSCode extensions**: Editor extensions
- **Mac App Store**: Apps installed via `mas`

### Window Management

Uses [AeroSpace](https://github.com/nikitabobko/AeroSpace) as the tiling window manager. Configuration is in [config/aerospace/aerospace.toml](config/aerospace/aerospace.toml).

### Key Remapping

Uses Karabiner-Elements for custom key bindings:
- Caps Lock → Esc
- Fn → Ctrl (when pressed with other keys)
- Command ↔ Ctrl remapping

## Configuration Files

### Terminal
- **Ghostty**: [config/ghostty/](config/ghostty/)

### Editors
- **VSCode**: [config/vscode/](config/vscode/) - settings, keybindings, extensions, snippets
- **Zed**: [config/zed/settings.json](config/zed/settings.json), [config/zed/keymap.json](config/zed/keymap.json)
- **Neovim**: [config/nvim/](config/nvim/)

### CLI Tools
- **Starship prompt**: [config/starship/](config/starship/)
- **Git**: [config/gitconfig](config/gitconfig), [config/gitignore_global](config/gitignore_global)
- **Lazygit**: [config/lazygit/](config/lazygit/)
- **K9s**: [config/k9s/](config/k9s/)
- **Bat**: [config/bat/](config/bat/)
- **Yazi**: [config/yazi/](config/yazi/)

## Development Notes

### Adding a New Zsh Plugin

1. Create `config/zsh/plugins/<tool>.zsh` following the plugin pattern
2. Include tool check, aliases, and completion setup
3. Plugin will auto-load via `zshrc` on next shell start

### Adding New Packages

1. Add to appropriate section in [Brewfile](Brewfile)
2. Run `brew bundle --file Brewfile` to install
3. For VSCode extensions, add to the `# VSCode extensions` section

### Modifying Dotfile Mappings

1. Edit [dotdrop.config.yml](dotdrop.config.yml) to add/modify file mappings
2. Add source file to `config/` directory
3. Run `dotdrop install` to deploy changes
