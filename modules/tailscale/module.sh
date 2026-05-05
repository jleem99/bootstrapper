#!/bin/bash
set -euo pipefail

log_info "Running tailscale module..."

module_check_supported "tailscale" "debian"
module_run_platform "tailscale"

log_success "Tailscale module completed successfully!"
