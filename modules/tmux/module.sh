#!/bin/bash
set -euo pipefail

log_info "Running tmux module..."

module_check_supported "tmux" "debian" "macos"
module_run_platform "tmux"

log_success "Tmux module completed successfully!"
