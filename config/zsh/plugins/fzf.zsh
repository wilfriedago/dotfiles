# =============================================================================================
# ~/.config/zsh/plugins/fzf.zsh
# =============================================================================================
# FZF (Fuzzy Finder) Zsh Plugin
# This plugin provides aliases and completion for FZF.
#
# It makes searching and navigating files and directories easier.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if FZF is installed
if (( ! $+commands[fzf] )); then
  return
fi

# Initialization — cached for faster startup
_cache_eval "fzf" "fzf --zsh" "$(command -v fzf)"

# `fzf --zsh` binds ^I to fzf-completion, which bypasses zsh's completion system entirely.
# fzf-tab claims ^I when it loads (see zshrc) and drives the real completion system instead,
# so nothing is rebound here. Ctrl+T / Alt+C / Ctrl+R keep their fzf widgets, and
# fzf-completion stays reachable through its `**` trigger.

# Preview snippet — runs in fzf's `--preview` subshell, so it can NOT reference
# zsh functions from the parent shell. Reused below by the standalone fzf bindings
# (Ctrl+T, Alt+C) and zoxide, via the {} placeholder.
_FZF_PREVIEW_SNIPPET='
  if [ -d "$1" ]; then
    eza -al --tree --icons --level=3 --no-permissions --no-user --no-time --no-filesize "$1" | head -100
  elif [ "$(file -Lbs --mime-type "$1" | cut -d/ -f1)" = "image" ]; then
    viu -w 100 "$1"
  else
    bat -n --color=always --line-range :100 "$1"
  fi
'

# `.fzf` is used to provide fzf configuration for the shell
export FZF_DEFAULT_COMMAND="
  fd \
  --strip-cwd-prefix \
  --type f \
  --type l \
  --hidden \
  --follow \
  --exclude ".git" \
  --exclude ".svn" \
  --exclude ".hg" \
  --exclude "CVS" \
  --exclude ".DS_Store" \
  --exclude ".worktrees" \
  --exclude "node_modules" \
  --exclude ".pytest_cache" \
  --exclude ".mypy_cache" \
  --exclude ".ropeproject" \
  --exclude ".hypothesis" \
  --exclude ".ruff_cache" \
  --exclude ".ipynb_checkpoints" \
  --exclude "__pycache__" \
  --exclude "coverage.xml" \
  --exclude ".cache" \
  --exclude ".idea" \
  --exclude ".venv" \
  --exclude "venv" \
  --exclude ".coverage" \
  --exclude "htmlcoverage" \
  --exclude "build" \
  --exclude "dist"
"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_DEFAULT_OPTS=" \
  --height 60% -1 \
  --select-1 \
  --reverse \
  --preview-window='right:60%:wrap' \
  --inline-info \
	--color=fg:#908caa,hl:#ebbcba \
	--color=fg+:#e0def4,hl+:#ebbcba \
	--color=border:#403d52,header:#31748f,gutter:#191724 \
	--color=spinner:#f6c177,info:#9ccfd8 \
	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa
"
export FZF_CTRL_R_OPTS=" \
  --preview 'echo {}' \
  --preview-window up:3:hidden:wrap \
  --bind 'ctrl-/:toggle-preview' \
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' \
  --color header:italic
"

export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS --preview \"zsh -c '$_FZF_PREVIEW_SNIPPET' _fzf_preview {}\""
export FZF_ALT_C_OPTS="$FZF_DEFAULT_OPTS --preview \"zsh -c '$_FZF_PREVIEW_SNIPPET' _fzf_preview {}\""

export _ZO_FZF_OPTS="
  --height 50% -1 \
  --select-1 \
  --reverse \
  --preview-window='right:wrap' \
  --inline-info \
  --cycle \
  --exit-0 \
  --tabstop=1 \
  --preview=\"zsh -c '$_FZF_PREVIEW_SNIPPET' _fzf_preview {2..}\"
"

# z() wrapper moved to directories.zsh where __zoxide_z is defined

# =============================================================================================
# fzf-tab — fzf as the completion menu
# =============================================================================================
# The plugin itself is declared in zshrc (it must load before the widget-wrapping plugins).
# It reads zsh's own completion output, so the zstyles in completions.zsh still apply;
# `menu no` there is required for fzf-tab to take over the menu.

zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' use-fzf-default-opts yes  # off by default; inherit $FZF_DEFAULT_OPTS above
zstyle ':fzf-tab:*' switch-group '<' '>'      # cycle completion groups (kills < > in the query)
zstyle ':fzf-tab:*' continuous-trigger '/'    # keep descending into directories on /
zstyle ':fzf-tab:*' single-group color header # keep the group header when there is only one
zstyle ':fzf-tab:*' prefix ''                 # drop the '·' marker in front of candidates
zstyle ':fzf-tab:*' fzf-min-height 15

# Previews run in a zsh subshell where fzf-tab exports $word, $group and $desc. It also
# exports $realpath, but only when the completer marked its candidates as files with
# `compadd -f` — carapace hands everything to _describe as plain values, so $realpath is
# missing for the ~680 commands it owns. Falling back to $word covers those: carapace
# returns whole cwd-relative paths. The -e test keeps non-path groups preview-free.
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  "ftb_target=\${realpath:-\$word}; [[ -e \$ftb_target ]] && zsh -c '$_FZF_PREVIEW_SNIPPET' _fzf_preview \$ftb_target"

# BSD ps: no --pid/--no-headers, so use -p with an empty format suffix.
zstyle ':fzf-tab:complete:(kill|ps|killport):argument-rest' fzf-preview 'ps -p $word -o command='
zstyle ':fzf-tab:complete:(kill|ps|killport):argument-rest' fzf-flags '--preview-window=down:3:wrap'

# Expand the value behind a variable name instead of previewing it as a path.
zstyle ':fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset|typeset):*' \
  fzf-preview 'echo ${(P)word}'

# Git: branches and refs get their log, paths get their diff.
zstyle ':fzf-tab:complete:git-(checkout|switch|rebase|merge|log|show):*' \
  fzf-preview 'git log --oneline --graph --color=always -20 $word --'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' \
  fzf-preview 'git diff --color=always -- $word'
