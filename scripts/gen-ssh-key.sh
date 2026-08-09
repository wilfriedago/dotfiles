#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <email> [key-path]" >&2
}

if (( $# < 1 || $# > 2 )) || [[ -z "$1" ]]; then
  usage
  exit 64
fi

email=$1
key_path=${2:-"$HOME/.ssh/id_ed25519"}
key_dir=$(dirname "$key_path")

if [[ -e "$key_path" || -e "$key_path.pub" ]]; then
  echo "Refusing to overwrite an existing SSH key: $key_path" >&2
  exit 1
fi

mkdir -p "$key_dir"
chmod 700 "$key_dir"

echo "Generating Ed25519 SSH key at $key_path..."
ssh-keygen -t ed25519 -C "$email" -f "$key_path"

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
  eval "$(ssh-agent -s)"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  ssh-add --apple-use-keychain "$key_path"
else
  ssh-add "$key_path"
fi

echo "Public key created at $key_path.pub"
if command -v pbcopy >/dev/null 2>&1; then
  echo "Copy it with: pbcopy < '$key_path.pub'"
fi
