#!/bin/zsh
for env in $(pyenv virtualenvs --bare | grep "^test-env-" | grep -v "/"); do echo "Removing $env..."; pyenv uninstall -f "$env"; done
