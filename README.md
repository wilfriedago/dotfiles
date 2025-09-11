 🏠 Wilfried's Dotfiles

This repository contains my personal dotfiles and system configuration for macOS and NixOS. It uses [`dotdrop`](https://github.com/deadc0de6/dotdrop) for configuration management and Nix flakes for NixOS systems.

## Overview

This dotfiles repository aims to:

- Quickly set up a new development environment
- Maintain consistent configurations across multiple machines
- Automate the installation of essential tools and applications
- Provide a modular and maintainable configuration system
- Use a tiling window manager for efficient window management

## 🚀 Setup

### Prerequisites

- Git

### macOS Installation

1. Clone the repository:

```sh
git clone https://github.com/wilfriedago/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Install dependencies and set up the environment

```sh
```

3. Deploy dotfiles

```sh
dotdrop install -c dotdrop.config.yaml -p default --force
dotdrop install -c dotdrop.config.yaml -p macos --force
```

### NixOS Installation

1. Clone the repository:

```sh
git clone https://github.com/wilfriedago/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Run the NixOS setup script:

```sh
./scripts/nixos/setup.sh
```

This will:
- Enable Nix flakes
- Generate hardware configuration
- Build and apply NixOS system configuration
- Set up Home Manager for user configuration
- Deploy additional dotfiles via dotdrop

3. Apply system settings (optional):

```sh
./scripts/nixos/settings.sh
```

#### Manual NixOS Setup

If you prefer manual setup:

1. Enable flakes in your Nix configuration
2. Update your `flake.nix` hostname and user details
3. Build the system:
   ```sh
   sudo nixos-rebuild switch --flake .#nixos
   ```
4. Set up Home Manager:
   ```sh
   nix run home-manager/master -- switch --flake .#wilfried
   ```

## Configuration Details

### Shell

For the shell, I am using [Zsh](https://www.zsh.org). I have a few plugins installed, but I try to keep them minimal to avoid clutter. My Zsh configuration is modular, with separate files for aliases, completions and functions. I also use [Starship](https://starship.rs) as my prompt. Check the [`config/zsh`](config/zsh) directory for my Zsh configuration and [`config/starship.toml`](config/starship.toml) for the Starship configuration.

In terms of command-line tools, I try to keep them minimal—only the ones I use daily, such as:

- [`bat`](https://github.com/sharkdp/bat) - A cat clone with syntax highlighting and Git integration
- [`btop`](https://github.com/ClementTsang/btop) - A terminal dashboard
- [`eza`](https://github.com/eza-community/eza) - A modern alternative to `ls`
- [`fd`](https://github.com/sharkdp/fd) - A simple, fast and user-friendly alternative to `find`
- [`fzf`](https://github.com/junegunn/fzf) - A command-line fuzzy finder
- [`k9s`](https://github.com/derailed/k9s) - A terminal UI for Kubernetes
- [`lazygit`](https://github.com/jesseduffield/lazygit) - A simple terminal UI for git commands
- [`lazydocker`](https://github.com/jesseduffield/lazydocker) - A simple terminal UI for Docker
- [`yazi`](https://github.com/sxyazi/yazi) - A terminal file manager
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) - A smarter `cd`

A complete list of configurations for each tool can be found in the [`Brewfile`](Brewfile#L57) directory.

### Terminal

I use [Ghossty](https://ghostty.org) as terminal emulator, which is a lightweight terminal emulator that supports tabs and has a minimalistic design. It is fast and responsive, making it ideal for development work. And as a bonus, it has a built-in terminal multiplexer.

### Application Launcher

I recently moved from the default macOS Spotlight to [Raycast](https://www.raycast.com). While it offers an impressive range of features and a sleek user experience, many of its advanced capabilities are locked behind a Pro subscription, which I find limiting. As a result, I'm currently exploring alternative solutions.

### Editors

#### VSCode

I use [VSCode](https://code.visualstudio.com) - it's a simple and yet very extensible and powerful editor.

Here's a list of [extensions](Brewfile#L124) I use daily, but I try to keep my `VSCode` setup as simple as possible. I tend to separate my work into different profiles, so I have a few profiles for different development contexts. Each profile has its own settings, keybindings, extensions, and snippets.

#### Zed

Despite my love for VSCode, it still has limitations and I like to explore new tools, so currently I am trying to move my day-to-day work to [Zed](https://zed.dev), which I think, as an editor, has a bright future. I like how it can be configured and the way plugins are installed.

My Zed plugins and configuration can be found [here](config/zed/settings.json), and the keymaps can be found [here](config/zed/keymap.json).

### Hotkey Daemons

Because I am using a primarily external keyboard and in most of my apps I rely on either Vi/Kakoune motions, I find it painful to use the mouse as it requires moving my right hand out of the keyboard and distracts my "zen" state :3. In most dev apps you can enable such modes, but in the default macOS apps or window manager such functionality is absent.
To resolve this issue I am using two daemons:
- [`Karabiner-Elements`](https://karabiner-elements.pqrs.org/) - to remap keys and create custom keybindings
  - I have a custom profile that allows me to use `Caps Lock` as `Esc` and `Ctrl` as `Command` key
  - I also have a custom profile for `Fn` key to act as `Ctrl` when pressed with other keys
  - I have a custom profile for `Command` key to act as `Ctrl` when pressed with other keys

### Window Management

#### macOS
As my main windows manager, I am using [`aerospace`](https://github.com/nikitabobko/AeroSpace) which is light and very configurable, and doesn't require to disable system integrity protection.
It works perfectly with `skhd` which allows me to focus and modify the layout without distractions.

#### NixOS
For NixOS, I use either [i3](https://i3wm.org) (for X11) or [Sway](https://swaywm.org) (for Wayland) as tiling window managers. Both provide similar functionality to AeroSpace with vim-like keybindings:

- **i3**: A lightweight X11 tiling window manager
- **Sway**: A Wayland compositor compatible with i3 configuration

The key bindings are configured to be similar to AeroSpace:
- `Alt + h/j/k/l` for focus navigation
- `Alt + Shift + h/j/k/l` for moving windows  
- `Alt + 1-9` for workspace switching
- `Alt + Shift + 1-9` for moving windows to workspaces

Configuration files are available in [`config/i3/config`](config/i3/config) and [`config/sway/config`](config/sway/config).

### Package Management

#### macOS
Uses [Homebrew](https://brew.sh) with packages defined in the [`Brewfile`](Brewfile). Install packages with:
```sh
brew bundle --global --file ~/.dotfiles/Brewfile
```

#### NixOS
Uses [Nix package manager](https://nixos.org/nix/) with packages defined declaratively in:
- [`nixos/configuration.nix`](nixos/configuration.nix) - System-wide packages
- [`nixos/home.nix`](nixos/home.nix) - User packages via Home Manager
- [`flake.nix`](flake.nix) - Flake inputs and outputs

See [`nixos/packages.md`](nixos/packages.md) for package equivalents between macOS and NixOS.

Update packages with:
```sh
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake ~/.dotfiles#nixos

# Update user packages
home-manager switch --flake ~/.dotfiles#wilfried
```

## Update and Sync

### macOS

To update your dotfiles after making changes:

```sh
# From the dotfiles directory
dotdrop update
```

To install your dotfiles on a new system:

```sh
dotdrop install -c dotdrop.config.yaml -p default --force
dotdrop install -c dotdrop.config.yaml -p macos --force
```

### NixOS

To update system configuration:

```sh
# Update flake inputs
nix flake update

# Rebuild system configuration
sudo nixos-rebuild switch --flake ~/.dotfiles#nixos

# Update user configuration
home-manager switch --flake ~/.dotfiles#wilfried

# Update dotfiles managed by dotdrop
dotdrop install -c dotdrop.config.yaml -p nixos --force
```

## Acknowledgements

Inspiration and code was taken from many sources, including:

- [Alicia Sykes](https://github.com/Lissy93) - https://github.com/Lissy93/dotfiles
- [Volodymyr Pivoshenko](https://github.com/pivoshenko) - https://github.com/pivoshenko/dotfiles
