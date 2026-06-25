#!/bin/bash
# Platforms: debian
set -euo pipefail

log_info "Running tailscale module..."

module_run_platform "tailscale"

log_success "Tailscale module completed successfully!"
