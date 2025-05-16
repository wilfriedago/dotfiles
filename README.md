 🏠 Wilfried's Dotfiles

This repository contains my personal dotfiles and system configuration for macOS. It uses [`dotdrop`](https://github.com/deadc0de6/dotdrop) and [`ansible`](https://github.com/ansible/ansible) to manage and deploy configuration files across different systems.

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
- Ansible

### Installation

1. Clone the repository:

```zsh
git clone https://github.com/wilfriedago/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Install dependencies and set up the environment

```sh
# install core: homebrew, zsh, oh-my-zsh and configs (optional)
ansible-playbook playbooks/shell.yml

# install dependencies
ansible-playbook playbooks/deps.yml
```

3. Deploy dotfiles

```sh
dotdrop install -c dotdrop.config.yaml -p default --force
dotdrop install -c dotdrop.config.yaml -p macos --force
```

## Configuration Details

### Shell

For the shell, I am using [Zsh](https://www.zsh.org). I have a few plugins installed, but I try to keep them minimal to avoid clutter. My Zsh configuration is modular, with separate files for aliases, completions and functions. I also use [Starship](https://starship.rs) as my prompt. Check the [`config/zsh`](config/zsh) directory for my Zsh configuration and [`config/starship.toml`](config/starship.toml) for the Starship configuration.

In terms of command-line tools, I try to keep them minimal—only the ones I use daily, such as:

- [`bat`](https://github.com/sharkdp/bat) - A cat clone with syntax highlighting and Git integration
- [`btop`](https://github.com/ClementTsang/btop) - A terminal dashboard
- [`exa`](https://github.com/ogham/exa) - A modern replacement for `ls`
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

As my main windows manager, I am using [`aerospace`](https://github.com/nikitabobko/AeroSpace) which is light and very configurable, and doesn't require to disable system integrity protection.
It works perfectly with `skhd` which allows me to focus and modify the layout without distractions.

## Update and Sync

To update your dotfiles after making changes:

```zsh
# From the dotfiles directory
dotdrop update
```

To install your dotfiles on a new system:

```zsh
dotdrop install
```

## Acknowledgements

Inspiration and code was taken from many sources, including:

- [Alicia Sykes](https://www.aliciasykes.com) - https://github.com/Lissy93/dotfiles
- [Volodymyr Pivoshenko](https://github.com/pivoshenko) - https://github.com/pivoshenko/dotfiles
