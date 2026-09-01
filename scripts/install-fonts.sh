#!/usr/bin/env bash
#
# Install the repository's vendored fonts into the user font directory.
#
# Fonts are copied, not symlinked: macOS Font Book and several apps read font
# files eagerly at login and handle symlinked faces inconsistently, so a real
# file is the reliable choice. Re-running is safe — files are only replaced when
# the repository copy is newer.

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
src_dir="$repo_root/assets/fonts"
dest_dir="$HOME/Library/Fonts"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "install-fonts: macOS only; ~/Library/Fonts does not apply here." >&2
  exit 1
fi

if [[ ! -d "$src_dir" ]]; then
  echo "install-fonts: no fonts directory at $src_dir" >&2
  exit 1
fi

shopt -s nullglob
fonts=("$src_dir"/*.otf "$src_dir"/*.ttf "$src_dir"/*.ttc)
shopt -u nullglob

if (( ${#fonts[@]} == 0 )); then
  echo "install-fonts: no font files found in $src_dir" >&2
  exit 1
fi

mkdir -p "$dest_dir"

installed=0
skipped=0
for font in "${fonts[@]}"; do
  target="$dest_dir/$(basename "$font")"
  if [[ -f "$target" && ! "$font" -nt "$target" ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  cp -f "$font" "$target"
  installed=$((installed + 1))
done

echo "install-fonts: ${installed} installed, ${skipped} already current (${dest_dir})"
