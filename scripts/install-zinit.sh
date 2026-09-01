#!/usr/bin/env bash
#
# Install the Zsh plugin manager.
#
# Deliberately explicit rather than self-installing from .zshrc: shell startup
# must never download and execute code from the network.

set -euo pipefail

zinit_dir="${ZINIT_INSTALL_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git}"

if [[ -r "$zinit_dir/zinit.zsh" ]]; then
  echo "zinit: already installed at $zinit_dir"
  exit 0
fi

mkdir -p "$(dirname "$zinit_dir")"
git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_dir"
echo "zinit: installed at $zinit_dir"
