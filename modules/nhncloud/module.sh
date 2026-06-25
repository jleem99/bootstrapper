#!/bin/bash
# Description: Configure NHN Cloud GPU instance (locale, gcsudo, bash shell)
# Platforms: debian
set -euo pipefail

log_info "Running nhncloud module..."

module_run_platform "nhncloud"

# nhncloud boxes use bash, not zsh; configure it with oh-my-bash + ble.sh + starship
run_module "bash"

log_success "NHN Cloud module completed successfully!"
