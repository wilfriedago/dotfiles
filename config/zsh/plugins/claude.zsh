# =============================================================================================
# ~/.config/zsh/plugins/claude.zsh
# =============================================================================================
# Claude Code Zsh Plugin
# This plugin provides aliases, completion and helpers for Claude Code.
#
# Claude Code is Anthropic's agentic coding CLI. It ships no native shell
# completion (Commander.js), so completion below is hand-written.
# For docs and more info, see: https://docs.claude.com/en/docs/claude-code
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Claude Code is installed
if (( ! $+commands[claude] )); then
  return
fi

# =============================================================================================
# Aliases
# =============================================================================================

alias cl='claude'
alias clc='claude --continue'                            # continue most recent conversation
alias clr='claude --resume'                              # resume a conversation (picker / session id)
alias clp='claude --print'                               # non-interactive: print response and exit
alias clv='claude --verbose'
alias cldoc='claude doctor'                              # health check the installation
alias clup='claude update'                               # check for and install updates
alias clmcp='claude mcp'                                 # manage MCP servers
alias clpl='claude plugin'                               # manage plugins

# Run with all permission checks bypassed — handy in throwaway sandboxes only.
alias clyolo='claude --dangerously-skip-permissions'

# =============================================================================================
# Functions
# =============================================================================================

# Headless one-shot prompt: `ask "summarize this repo"` (reads stdin too: `cat x | ask ...`).
function ask() {
  claude --print "$@"
}

# Pipe-friendly prompt that forces plain-text output, e.g. `git diff | clpipe "write a commit msg"`.
function clpipe() {
  claude --print --output-format text "$@"
}

# =============================================================================================
# Completions (hand-written — Claude Code has no native completion generator)
# =============================================================================================
_claude() {
  local -a commands global_flags

  commands=(
    'agents:Manage background agents'
    'auth:Manage authentication'
    'auto-mode:Inspect auto mode classifier configuration'
    'doctor:Check the health of the Claude Code auto-updater'
    'install:Install Claude Code native build'
    'mcp:Configure and manage MCP servers'
    'plugin:Manage Claude Code plugins'
    'project:Manage Claude Code project state'
    'setup-token:Set up a long-lived authentication token'
    'ultrareview:Run a cloud-hosted multi-agent code review'
    'update:Check for updates and install if available'
  )

  global_flags=(
    '(-c --continue)'{-c,--continue}'[Continue the most recent conversation]'
    '(-r --resume)'{-r,--resume}'[Resume a conversation by session id or picker]:session id:'
    '(-p --print)'{-p,--print}'[Print response and exit (non-interactive)]'
    '--model[Model for the current session]:model:'
    '--agent[Agent for the current session]:agent:'
    '--effort[Effort level]:level:(low medium high xhigh max)'
    '--permission-mode[Permission mode]:mode:(default acceptEdits plan bypassPermissions)'
    '--output-format[Output format (with --print)]:format:(text json stream-json)'
    '--add-dir[Additional directories to allow tool access to]:directory:_files -/'
    '--mcp-config[Load MCP servers from JSON files]:config:_files'
    '--settings[Path to a settings JSON file or JSON string]:settings:_files'
    '--verbose[Enable verbose output]'
    '--dangerously-skip-permissions[Bypass all permission checks]'
    '(-d --debug)'{-d,--debug}'[Enable debug mode]'
    '(-h --help)'{-h,--help}'[Show help]'
    '(-v --version)'{-v,--version}'[Show version]'
  )

  _arguments -C \
    $global_flags \
    '1: :->command' \
    '*:: :->args' && return 0

  case $state in
    command) _describe -t commands 'claude command' commands ;;
  esac
}

compdef _claude claude
compdef _claude cl
