#!/bin/bash
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running direnv module..."

install_packages "direnv"

log_success "Direnv installed successfully!"

mkdir -p ~/.config/direnv
cp "$(module_dir)/direnvrc" ~/.config/direnv/direnvrc

echo 'eval "$(direnv hook '$(get_current_shell)')"' >> "$(get_shell_profile)"

log_success "Direnv configuration added to ~/.config/direnv/direnvrc"

log_success "Direnv module completed successfully!" 