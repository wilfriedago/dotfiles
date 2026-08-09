# CLAUDE.md

Guidance for agents working in this macOS dotfiles repository.

## Repository model

- `dotdrop.config.yml` deploys configuration from this repository.
- Dotfiles use absolute symlinks by default; editing a deployed file usually edits the repository directly.
- Preserve unrelated working-tree changes. This repository is frequently edited through deployed symlinks.
- Do not use an unscoped `dotdrop update`. Directory updates can remove repository files missing from the destination.
- Use `just install-force <profile>` only when replacing known conflicts is intentional.

## Commands

```sh
just zinit-install      # explicitly install the Zsh plugin manager
just install default   # deploy cross-application configuration
just install macos     # deploy VS Code/macOS-specific configuration
just compare           # compare deployed state with the repository
just brew-sync         # install the curated Brewfile
just macos             # apply macOS defaults
just check             # run repository validation
```

## Dotdrop rules

- `default` contains shell, terminal, Git, editor, Kubernetes, and CLI configuration.
- `macos` contains VS Code settings, snippets, keybindings, and UI customization.
- `d_gh`, `d_helm`, `d_k9s`, and `d_nvim` use `link_children` because those applications write runtime state into their config directories.
- `f_vscode_extensions` uses `nolink` because VS Code generates and rewrites it.
- Avoid Dotdrop templates: rendered files would no longer link directly to the repository source.
- Never link an application-owned directory if it may contain credentials or generated state.

## Zsh architecture

- `config/zsh/zshenv` defines XDG paths and variables required by all Zsh sessions.
- `config/zsh/zprofile` initializes Homebrew for login shells.
- `config/zsh/zshrc` loads Zinit, shared shell modules, tool plugins, and Mise.
- Zinit must be installed explicitly with `just zinit-install`; shell startup must not download code.
- Files in `config/zsh/plugins/` are sourced explicitly from `zshrc`.
- Tool and framework plugins must guard themselves with `(( $+commands[tool] )) || return` rather than inspecting the shell's initial working directory.
- Initialize completion before sourcing plugins that call `compdef`.
- Cache generated completions under `$ZSH_CACHE_DIR/completions`.
- Keep Mise activation last so its runtime paths stay ahead of earlier PATH modifications.

## Package management

- `Brewfile` is one curated inventory, not a machine-generated dump.
- Keep taps, casks, formulae, VS Code extensions, and App Store entries alphabetized within their sections.
- Add only direct tools and applications, not transitive dependencies.
- Use `just brew-sync`; do not restore a forceful Brewfile dump recipe.

## Scripts

- Scripts belong under `scripts/` and are deployed to `~/.scripts`.
- Bash scripts use `set -euo pipefail`, quote expansions, validate arguments, and refuse unintended overwrites.
- `scripts/macos/settings.sh` must remain safe to rerun and must reject non-macOS hosts.
- `scripts/gen-ssh-key.sh` creates keys only; `config/ssh.conf` remains the owner of SSH configuration.

## Validation

Run `just check` before finishing changes. It checks whitespace, ShellCheck when available, Bash and Zsh syntax, secrets, Dotdrop profiles, and Brewfile syntax. GitHub Actions installs all validation tools and runs the same recipe on macOS.
