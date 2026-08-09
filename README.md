# 🏠 Wilfried's Dotfiles

My personal dotfiles and macOS system configuration, managed with [`dotdrop`](https://github.com/deadc0de6/dotdrop).

## Overview

This repository aims to:

- Quickly set up a new development environment
- Maintain consistent configurations across multiple machines
- Automate the installation of essential tools and applications
- Provide a modular and maintainable configuration system
- Use a tiling window manager for efficient window management

Configuration is deployed as **symlinks** pointing back into this repository, so `~/.zshrc` and [`config/zsh/zshrc`](config/zsh/zshrc) are the same file. Edit either one, commit from here — there is no copy step to remember.

## 🚀 Setup

### Prerequisites

- Git
- [Homebrew](https://brew.sh)

### Installation

1. Clone the repository:

```sh
git clone https://github.com/wilfriedago/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Install packages and applications:

```sh
brew bundle --file Brewfile
just zinit-install
```

3. Deploy the dotfiles:

```sh
dotdrop install -c dotdrop.config.yml -p default
dotdrop install -c dotdrop.config.yml -p macos
```

Inspect conflicts before replacing existing files. If replacement is intentional, use
`just install-force <profile>` after backing up anything you want to keep.

4. Apply macOS system settings:

```sh
bash ~/.scripts/macos/settings.sh
```

## Configuration Details

### Shell

I use [Zsh](https://www.zsh.org) with a deliberately small plugin set. The configuration is modular, with separate files for aliases, completions, functions and settings, plus a [`plugins`](config/zsh/plugins) directory holding one file per tool. My prompt is [Starship](https://starship.rs).

See [`config/zsh`](config/zsh) for the shell configuration and [`config/starship`](config/starship) for the prompt.

For command-line tools I stick to the ones I use daily:

- [`bat`](https://github.com/sharkdp/bat) - a `cat` clone with syntax highlighting and Git integration
- [`btop`](https://github.com/aristocratos/btop) - a terminal resource monitor
- [`eza`](https://github.com/eza-community/eza) - a modern alternative to `ls`
- [`fd`](https://github.com/sharkdp/fd) - a simple, fast and user-friendly alternative to `find`
- [`fzf`](https://github.com/junegunn/fzf) - a command-line fuzzy finder
- [`k9s`](https://github.com/derailed/k9s) - a terminal UI for Kubernetes
- [`yazi`](https://github.com/sxyazi/yazi) - a terminal file manager
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) - a smarter `cd`

The complete curated package list lives in [`Brewfile`](Brewfile).

### Terminal

I use [Ghostty](https://ghostty.org) as my terminal emulator — lightweight, GPU-accelerated, with a minimal design and a built-in multiplexer.

### Editors

#### VSCode

[VSCode](https://code.visualstudio.com) is my main editor — simple, yet extensible and powerful. Its extensions are listed in [`Brewfile`](Brewfile), and I keep the setup as lean as I can. I separate work into profiles, each with its own settings, keybindings, extensions and snippets.

Settings, keybindings, snippets and UI customisations live in [`config/vscode`](config/vscode).

#### Neovim

A [LazyVim](https://www.lazyvim.org)-based configuration in [`config/nvim`](config/nvim), used for quick edits and remote work.

### Window Management

My window manager is [`aerospace`](https://github.com/nikitabobko/AeroSpace) — light, very configurable, and it doesn't require disabling System Integrity Protection. Configuration is in [`config/aerospace`](config/aerospace).

## Update and Sync

Because dotfiles are symlinked, changes you make to a deployed config are already changes in this repository:

```sh
cd ~/.dotfiles
git status
git commit -am "chore: update configuration"
```

To check that everything on disk still matches the repository:

```sh
dotdrop compare -c dotdrop.config.yml -p default
dotdrop compare -c dotdrop.config.yml -p macos
```

Re-run `dotdrop install` only after adding a new dotfile mapping, or on a new machine.

Validate the repository before committing:

```sh
just check
```

## Acknowledgements

Inspiration and code was taken from many sources, including:

- [Alicia Sykes](https://github.com/Lissy93) - https://github.com/Lissy93/dotfiles
- [Volodymyr Pivoshenko](https://github.com/pivoshenko) - https://github.com/pivoshenko/dotfiles
