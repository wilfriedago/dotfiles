#!/usr/bin/env bash
#
# Verify this MACHINE's deployed state.
#
# `just check` validates the repository and can run in CI. `just doctor` validates
# what is actually on disk here — symlinks, binaries, deployed files — and cannot.
# Keeping them separate is what stops "the repo is valid" from being mistaken for
# "this machine is correct".

set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 1

fail=0
warn=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail + 1)); }
note() { printf '  \033[33m!\033[0m %s\n' "$1"; warn=$((warn + 1)); }

echo 'Deployment'

missing_src=$(python3 - <<'PY'
import yaml, os
c = yaml.safe_load(open("dotdrop.config.yml"))
for k, v in (c.get("dotfiles") or {}).items():
    if not os.path.exists(v.get("src", "")):
        print(f"{k} -> {v.get('src')}")
PY
)
if [[ -z "$missing_src" ]]; then
  ok 'every dotdrop src exists'
else
  while IFS= read -r l; do bad "dotdrop src missing: $l"; done <<< "$missing_src"
fi

dangling_refs=$(python3 - <<'PY'
import yaml
c = yaml.safe_load(open("dotdrop.config.yml"))
defs = set(c.get("dotfiles") or {})
for prof, body in (c.get("profiles") or {}).items():
    for k in (body.get("dotfiles") or []):
        if k not in defs:
            print(f"{prof} -> {k}")
PY
)
if [[ -z "$dangling_refs" ]]; then
  ok 'no dangling profile references'
else
  while IFS= read -r l; do bad "profile references undefined entry: $l"; done <<< "$dangling_refs"
fi

untracked_src=$(python3 - <<'PY'
import yaml, subprocess
c = yaml.safe_load(open("dotdrop.config.yml"))
for k, v in (c.get("dotfiles") or {}).items():
    src = v.get("src", "")
    r = subprocess.run(["git", "ls-files", "--error-unmatch", src], capture_output=True)
    if r.returncode != 0:
        print(f"{k} -> {src}")
PY
)
if [[ -z "$untracked_src" ]]; then
  ok 'every dotdrop src is tracked by git'
else
  while IFS= read -r l; do note "untracked, so absent from a fresh clone: $l"; done <<< "$untracked_src"
fi

dangling=$(find "$HOME/.config" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null \
  | grep -v swiftpm || true)
if [[ -z "$dangling" ]]; then
  ok 'no dangling symlinks under ~/.config'
else
  while IFS= read -r l; do bad "dangling symlink: $l"; done <<< "$dangling"
fi

echo
echo 'Shell'

unsourced=''
for f in config/zsh/plugins/*.zsh; do
  b=$(basename "$f")
  grep -q "plugins/$b" config/zsh/zshrc || unsourced+="$b "
done
if [[ -z "$unsourced" ]]; then
  ok 'every plugin is sourced by zshrc'
else
  bad "plugin files never sourced: $unsourced"
fi

dupes=$(zsh -l -i -c 'zsh -c "print -l \$path"' 2>/dev/null | sort | uniq -d | tr '\n' ' ')
if [[ -z "$dupes" ]]; then
  ok 'PATH has no duplicates in nested shells'
else
  bad "duplicate PATH entries: $dupes"
fi

# -L follows the plugins symlink; without it the 27 plugin .zwc go uncounted.
zwc=$(find -L "$HOME/.config/zsh" -name '*.zwc' 2>/dev/null | wc -l | tr -d ' ')
if (( zwc > 0 )); then
  ok "zsh sources byte-compiled ($zwc .zwc files)"
else
  note 'no .zwc files — is ~/.zlogin deployed?'
fi

echo
echo 'Commands referenced by config'
for c in bat eza fzf fd rg zoxide starship mise jq trash difft viu gh k9s kubectl helm; do
  if command -v "$c" >/dev/null 2>&1; then
    ok "$c"
  else
    bad "$c is referenced by config but not installed"
  fi
done

echo
echo 'Git'
signers=$(git config --get gpg.ssh.allowedSignersFile 2>/dev/null)
signers="${signers/#\~/$HOME}"
if [[ -n "$signers" && -f "$signers" ]]; then
  ok 'allowed_signers present (signatures verifiable)'
else
  bad 'gpg.ssh.allowedSignersFile is set but the file is missing'
fi

if git config --get-regexp '^includeif\.' >/dev/null 2>&1; then
  ok 'conditional work identity configured'
else
  note 'no includeIf — every commit uses one identity'
fi

if [[ -x .git/hooks/pre-commit ]]; then
  ok 'pre-commit hook installed'
else
  bad 'no pre-commit hook — run: just hooks'
fi

echo
echo 'Fonts'
missing_fonts=0
for f in assets/fonts/*.otf assets/fonts/*.ttf; do
  [[ -e "$f" ]] || continue
  [[ -f "$HOME/Library/Fonts/$(basename "$f")" ]] || missing_fonts=$((missing_fonts + 1))
done
if (( missing_fonts == 0 )); then
  ok 'vendored fonts installed'
else
  bad "$missing_fonts vendored font(s) not installed — run: just fonts"
fi

echo
if (( fail )); then
  echo "doctor: ${fail} problem(s), ${warn} warning(s)."
  exit 1
fi
echo "doctor: healthy (${warn} warning(s))."
