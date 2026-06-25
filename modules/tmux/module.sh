#!/bin/bash
# Platforms: debian
set -euo pipefail

log_info "Running tmux module..."

module_run_platform "tmux"

log_success "Tmux module completed successfully!"
