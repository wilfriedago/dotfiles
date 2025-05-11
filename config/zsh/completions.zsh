# Load Angular CLI autocompletion.
source <(ng completion script)

# Make sure hidden files are included in globbing
setopt globdots

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

zstyle ':completion:*' fzf-search-display true

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'

# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

# hide parents
zstyle ':completion:*' ignored-patterns '.|..|.DS_Store|**/.|**/..|**/.DS_Store|**/.git'

# hide `..` and `.` from file menu
zstyle ':completion:*' ignore-parents 'parent pwd directory'

# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# complete `ls` / `cat` / etc
zstyle ':fzf-tab:complete:(\\|*/|)(ls|gls|bat|cat|cd|rm|cp|mv|ln|hx|code|open|source|z|eza):*' fzf-preview '_fzf_complete_realpath "$realpath"'

# Add an additional debug line to verify when preview is called
zstyle ':fzf-tab:complete:(\\|*/|)(ls):*' fzf-flags --preview-window=right:60%

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
z () {
  \__zoxide_z "$@"
}
