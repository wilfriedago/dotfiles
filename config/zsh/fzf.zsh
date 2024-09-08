# `.fzf` is used to provide fzf configuration for the shell

# =============================================================================================
# fzf
# =============================================================================================

if [[ ! "$PATH" == */opt/fzf/bin* ]]; then
  export PATH="$PATH:$(brew --prefix)/opt/fzf/bin"
  eval "$(fzf --zsh)"
  source "$HOME/.scripts/fzf/fzf-git.sh"
  source "$HOME/.scripts/fzf/fzf-zsh-completion.sh"
fi


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
  --inline-info
"
export FZF_CTRL_R_OPTS=" \
  --preview 'echo {}' \
  --preview-window up:3:hidden:wrap \
  --bind 'ctrl-/:toggle-preview' \
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' \
  --color header:italic
"

export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS --preview '_fzf_complete_realpath {}'"
export FZF_ALT_C_OPTS="$FZF_DEFAULT_OPTS --preview '_fzf_complete_realpath {}'"

# =============================================================================================
# zoxide
# =============================================================================================

export _ZO_FZF_OPTS="
  --height 40% -1 \
  --select-1 \
  --reverse \
  --preview-window='right:wrap' \
  --inline-info \
  --cycle \
  --exit-0 \
  --tabstop=1 \
  --preview='_fzf_complete_realpath {2..}'
"

# remap default keybinding with `z name<tab>`
eval "$(zoxide init zsh --no-cmd)"
z () {
  \__zoxide_z "$@"
}
