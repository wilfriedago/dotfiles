# Dotfiles operator interface.
#
#   just bootstrap   fresh machine -> working workstation
#   just apply       deploy dotfiles after adding a mapping
#   just update      upgrade every package manager
#   just doctor      is THIS MACHINE correct?
#   just check       is the REPOSITORY valid?  (also runs in CI)
#
# Run `just --list` for everything else.

default_profile := "default"
config := justfile_directory() / "dotdrop.config.yml"
scripts := justfile_directory() / "scripts"
githooks := justfile_directory() / ".githooks"

# List all available recipes
_default:
  @just --list

# ── Lifecycle ────────────────────────────────────────────────────────────────

# Fresh machine -> working workstation. Safe to re-run.
bootstrap: brew-sync fonts zinit-install
  @just apply {{default_profile}}
  @just apply macos
  mise install
  @just hooks
  @echo ""
  @echo "Bootstrap complete. Next:"
  @echo "  just macos       apply system settings (needs a logout afterwards)"
  @echo "  just credentials set up SSH and GitHub auth"
  @echo "  just doctor      verify the result"

# Deploy dotfiles for a profile (no overwriting of existing files)
apply profile=default_profile:
  dotdrop install --cfg={{config}} --profile={{profile}}

# Deploy and explicitly replace conflicts
apply-force profile=default_profile:
  dotdrop install --cfg={{config}} --profile={{profile}} --force

# Upgrade every package manager
update:
  brew update && brew upgrade && brew cleanup
  mise upgrade
  gh extension upgrade --all
  zsh -ic 'zinit self-update && zinit update --all' || true

# ── Verification ─────────────────────────────────────────────────────────────

# Is THIS MACHINE correct? Checks deployed state; cannot run in CI.
doctor:
  @bash {{scripts}}/doctor.sh

# Is the REPOSITORY valid? Runs in CI too.
check:
  git diff --check
  shellcheck {{scripts}}/*.sh {{scripts}}/macos/*.sh {{githooks}}/pre-commit
  bash -n {{scripts}}/*.sh {{scripts}}/macos/*.sh
  zsh -n config/zsh/*.zsh config/zsh/zshrc config/zsh/zprofile config/zsh/zshenv config/zsh/zlogin config/zsh/zlogout config/zsh/plugins/*.zsh
  gitleaks detect --source . --no-banner --redact --no-git
  dotdrop files --cfg={{config}} --profile=default >/dev/null
  dotdrop files --cfg={{config}} --profile=macos >/dev/null
  ruby -c Brewfile >/dev/null
  python3 -c "import tomllib; tomllib.load(open('config/aerospace/aerospace.toml','rb'))"
  python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in ['config/k9s/config.yaml','config/k9s/aliases.yaml','dotdrop.config.yml']]"

# Compare deployed files with the repository
compare:
  dotdrop compare --cfg={{config}} --profile=default
  dotdrop compare --cfg={{config}} --profile=macos

# ── Components ───────────────────────────────────────────────────────────────

# Install the curated Brewfile
brew-sync:
  brew bundle --file {{justfile_directory()}}/Brewfile

# Install vendored fonts into ~/Library/Fonts
fonts:
  @bash {{scripts}}/install-fonts.sh

# Install git hooks
hooks:
  @ln -sf {{githooks}}/pre-commit {{justfile_directory()}}/.git/hooks/pre-commit
  @echo "pre-commit hook installed"

# Install the Zsh plugin manager (shell startup must never download code)
zinit-install:
  @bash {{scripts}}/install-zinit.sh

# Apply macOS system settings
macos:
  @bash {{scripts}}/macos/settings.sh

# Interactive: SSH key, GitHub auth, commit signing
credentials:
  @bash {{scripts}}/credentials.sh

# ── Diagnostics ──────────────────────────────────────────────────────────────

# Benchmark shell startup
shell-bench:
  @if command -v hyperfine >/dev/null; then \
     hyperfine --warmup 3 --shell=none 'zsh -i -c exit'; \
   else \
     echo "hyperfine not installed; falling back to 15 timed runs"; \
     for i in $(seq 1 15); do \
       s=$(python3 -c 'import time;print(int(time.time()*1000))'); \
       zsh -i -c exit 2>/dev/null; \
       e=$(python3 -c 'import time;print(int(time.time()*1000))'); \
       echo $((e-s)); \
     done | sort -n | awk '{a[NR]=$1} END{print "min="a[1]" median="a[int(NR/2)+1]" max="a[NR]" (ms)"}'; \
   fi
  @uptime | sed 's/.*load/load/'
