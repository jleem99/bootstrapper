#!/bin/bash
# Description: Configure NHN Cloud GPU instance (locale, gcsudo, bash shell)
# Platforms: debian
set -euo pipefail

log_info "Running nhncloud module..."

# Run platform-specific implementation
module_run_platform

run_module "basic-packages"
# nhncloud boxes use bash, not zsh; configure it with oh-my-bash + ble.sh + starship
run_module "bash"
run_module "tmux"
run_module "neovim"
run_module "claude"

log_success "NHN Cloud module completed successfully!"
