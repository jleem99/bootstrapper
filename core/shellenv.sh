#!/bin/bash
# Core command: bootstrapper shellenv [bash|zsh|fish]
# Prints the bootstrapper() wrapper function for the given shell.
# Designed to be eval'd:
#   eval "$(bootstrapper shellenv bash)"
#   bootstrapper shellenv fish | source

print_shellenv "${1:-$(get_current_shell)}"
