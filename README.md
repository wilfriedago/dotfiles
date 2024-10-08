# wilfriedago's dotfiles

- [wilfriedago's dotfiles](#wilfriedagos-dotfiles)
  - [Contents](#contents)
  - [Main principles](#main-principles)
  - [Installation](#installation)
  - [Apps](#apps)
  - [VSCode](#vscode)
  - [Hotkey Daemons](#hotkey-daemons)
  - [Tiling Windows Manager](#tiling-windows-manager)
  - [CLI](#cli)
    - [fzf](#fzf)
  - [Local configuration](#local-configuration)

## Contents

What's in here?

- All my `brew` dependencies including applications, fonts, LSPs etc. See [`Brewfile`](playbooks/deps/Brewfile)
- All my `macOS` configuration. See [`macos`](.scripts/macos/default.sh) and [`macos`](.scripts/macos/settings.sh)
- All my shell configurations. See [`.config/zsh`](.config/zsh) and [`.zshrc`](.zshrc)
- All my `VSCode` configurations and extensions. See [`vscode/`](.vscode) and [`extensions`](playbooks/deps/Brewfile)
- All my rest [`.configs/`](.config) :3

## Main principles

- Minimalism in everything
- Consistency
- Simplicity
- One style - [JetBrainsMono](https://www.jetbrains.com/lp/mono) font
- Reduced visual noise, only important things should be shown
- "Please, do not touch my code" - minimal auto-formatting or code flow interruptions
- Security - do not share anything with anyone

## Installation

> [!IMPORTANT]
> I am planning to use [`dotbot`](https://github.com/anishathalye/dotbot) to set everything instead of `ansible` and `dotdrop` as it doesn't require any external dependencies and can be used as a submodule

I am using [`dotdrop`](https://github.com/deadc0de6/dotdrop) to manage dotfiles and [`ansible`](https://github.com/ansible/ansible) to set things up. Steps:

1. Clone this repo with: `git clone https://github.com/wilfriedago/dotfiles ~/.dotfiles`
2. `cd ~/.dotfiles/`
3. Run the following commands to install the necessary tooling:

```shell
# install core: homebrew, zsh, oh-my-zsh and configs (optional)
ansible-playbook playbooks/shell.yml

# install dependencies
ansible-playbook playbooks/deps.yml
```

4. Run the following commands to install configs:

```shell
dotdrop -c ".config/dotdrop/config.yml" -p default install -f

# macOS only!
dotdrop -c ".config/dotdrop/config.yml" -p macos install -f
```

## Apps

I am using [`brew`](https://brew.sh) to install all free apps for my Mac.
I also sync apps from the App Store with `brew` via [`mas`](https://formulae.brew.sh/formula/mas), so the resulting [`Brewfile`](playbooks/deps/Brewfile) contains everything.

## VSCode

![vscode](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/vscode.png)

Here's a list of [`extensions`](playbooks/deps/Brewfile) I use daily, but I try to keep my `VSCode` setup as simple as possible.

I also quite heavily use [`helix`](https://github.com/helix-editor/helix) for in-terminal editing. You can find my `helix` and LSPs configuration [here](dotfiles/.config/helix).

## Hotkey Daemons

Because I am using a primarily external keyboard and in most of my apps I rely on either Vi/Kakoune motions I find it painful to use the mouse as it requires moving my right hand out of the keyboard and distracts my "zen" state :3 In most the dev apps you can enable such modes but in the default MacOS apps or windows manager such functionality is absent
To resolve this issue I am using two daemons:

- [Karabiner](https://karabiner-elements.pqrs.org) - to enable the Vi motions system-wise and rebind some of the keys for example `caps lock -> lctrl`
- [`skhd`](https://github.com/koekeishiya/skhd) - to manage keybinding for tilling window manager

## Tiling Windows Manager

As my main tiling windows manager I am using [`aerospace`](https://github.com/nikitabobko/AeroSpace) which is light and very configurable, and doesn't require to disable system integrity protection.
It works perfectly with `skhd` which allows me to focus and modify the layout without distractions.

## CLI

I am using [`Warp`](https://www.warp.dev) as my main terminal.
As the main shell I am using [`zsh`](https://www.zsh.org) with [`oh-my-zsh`](https://github.com/ohmyzsh/ohmyzsh) and [`starship`](https://github.com/starship/starship). To manage shell plugins I am using [`zplug`](https://github.com/zplug/zplug).
I also have some tools/scripts/aliases to make my working experience better.
But, I try to keep them minimal: only ones I truly use.

I mainly work with:

- `Java & Kotlin` - For backend development
- `JavaScript & TypeScript` - For frontend development
- `Python` - For data science, machine learning and overall scripting

I also have several other languages installed. But I don't use them daily:

- `Rust`
- `Go`

### fzf a.k.a. Fuzzy Finder

I use [`fzf`](https://github.com/junegunn/fzf) for several tasks:

- `tab` to autocomplete probably all the tools using [`fzf-tab`](https://github.com/Aloxaf/fzf-tab)

![fzf-tab](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/fzf_tab.png)

- `ctrl+r` to fuzzy search command history

![fzf-ctrl+r](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/fzf_ctrl_r.png)

- `ctrl+t` to fuzzy search files and dirs in the current tree to include paths in commands with instant previews for text files (content) and directories (inner tree)

![fzf-ctrl+t](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/fzf_ctrl_t.png)

- `ctrl+k` to fuzzy search files by name and open/edit them

![fzf-ctrl+k](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/fzf_ctrl_k.png)

- `ctrl+f` to fuzzy search files by content and open/edit them

![fzf-ctrl+f](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/fzf_ctrl_f.png)

- `ctrl+g` to work `git` using [`fzf-git`](https://github.com/junegunn/fzf-git.sh)

![fzf-ctrl+g](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/fzf_ctrl_g.png)

- `z <name> tab` to enable fuzzy finder for [`zoxide`](https://github.com/ajeetdsouza/zoxide)

![fzf-z+tab](https://raw.githubusercontent.com/pivoshenko/dotfiles/master/docs/assets/fzf_z_tab.png)

## Local configuration

Some of the used tools require local configuration, such as `git` with username and email.

Here's the full list:

- `~/.gitconfig.local` to store any user-specific data
- `~/.shell/.local` to store local shell config, like usernames, passwords, tokens, `gpg` keys etc
