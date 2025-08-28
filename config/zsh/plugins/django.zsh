# =============================================================================================
# ~/.config/zsh/plugins/django.zsh
# =============================================================================================
# Django Zsh Plugin
# This plugin provides aliases and completion for Django.
#
# Makes life easier when working with Django projects.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Check if Python is installed
if (( ! $+commands[python3] )); then
  return
fi

# Aliases
alias dj='python manage.py'
alias djdd='python manage.py dumpdata'
alias djld='python manage.py loaddata'
alias djm='python manage.py migrate'
alias djsh='python manage.py shell'
alias djsm='python manage.py schemamigration'
alias djs='python manage.py syncdb --noinput'
alias djt='python manage.py test'
alias djrs='python manage.py runserver'
