#!/usr/bin/env zsh

# aliases
alias python='python3'
alias pip='pip3'
alias py='python3'
alias py2='python2'
alias pir='pip install -r requirements.txt'

# PYTHON
[ -d "$PWD/.venv" ] && source "$PWD/.venv/bin/activate" # Automatically load Python virtual environment if available
