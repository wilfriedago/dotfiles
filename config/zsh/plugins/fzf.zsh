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

_fzf_completion_realpath() {
  if [ -d "$1" ]; then
    eza -al --tree --icons --level=3 --no-permissions --no-user --no-time --no-filesize "$1" | head -100
  else
    mime="$(file -Lbs --mime-type "$1")"
    category="${mime%%/*}"
    if [ "$category" = 'image' ]; then
      chafa -r2 -w 100 "$1"
    else
      bat -n --color=always --line-range :100 "$1"
    fi
  fi
}

# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# complete `ls` / `cat` / etc
zstyle ':fzf-tab:complete:(\\|*/|)(ls|gls|bat|cat|cd|rm|cp|mv|ln|hx|code|open|source|z|eza):*' fzf-preview '_fzf_completion_realpath "$realpath"'

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
  --height 30% -1 \
  --select-1 \
  --reverse \
  --preview-window='right:wrap' \
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

export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS --preview '_fzf_completion_realpath {}'"
export FZF_ALT_C_OPTS="$FZF_DEFAULT_OPTS --preview '_fzf_completion_realpath {}'"

export _ZO_FZF_OPTS="
  --height 50% -1 \
  --select-1 \
  --reverse \
  --preview-window='right:wrap' \
  --inline-info \
  --cycle \
  --exit-0 \
  --tabstop=1 \
  --preview='_fzf_completion_realpath {2..}'
"

# z() wrapper moved to directories.zsh where __zoxide_z is defined
