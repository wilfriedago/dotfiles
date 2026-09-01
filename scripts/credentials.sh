#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
key_path="$HOME/.ssh/id_ed25519"

step() { printf '\n\033[1m%s\033[0m\n' "$1"; }

step '1. SSH key'
if [[ -f "$key_path" ]]; then
  echo "   Existing key at $key_path — leaving it alone."
else
  read -r -p '   Email for the key comment: ' email
  bash "$repo_root/scripts/gen-ssh-key.sh" "$email"
fi

step '2. Add the key to GitHub'
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo '   Already authenticated with gh.'
  else
    echo '   Opening GitHub login...'
    gh auth login --git-protocol ssh --hostname github.com
  fi
  if ! gh ssh-key list 2>/dev/null | grep -q "$(awk '{print $2}' "$key_path.pub" | cut -c1-24)"; then
    echo '   Uploading the public key...'
    gh ssh-key add "$key_path.pub" --title "$(scutil --get ComputerName 2>/dev/null || hostname)" || true
  else
    echo '   Public key already on the account.'
  fi
else
  echo '   gh not installed; add this key manually at https://github.com/settings/keys:'
  cat "$key_path.pub"
fi

step '3. Commit signing'
signers="$HOME/.config/git/allowed_signers"
if [[ -f "$signers" ]]; then
  pub=$(awk '{print $1" "$2}' "$key_path.pub")
  if grep -qF "$pub" "$signers"; then
    echo "   This key is already trusted in $signers."
  else
    echo "   NOTE: $key_path.pub is not listed in $signers."
    echo "   Add a line there so git can verify your own signatures:"
    echo "     <your-email> $pub"
  fi
else
  echo "   No $signers — signature verification will not work."
fi

step '4. Verify'
echo '   git:  ' "$(git config --get user.email)"
ssh -T git@github.com 2>&1 | head -1 | sed 's/^/   ssh:   /' || true

printf "\nCredentials done. Run: just doctor\n"
