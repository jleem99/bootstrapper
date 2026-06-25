#!/bin/bash
# Platforms: debian
set -euo pipefail

log_info "Running tailscale module..."

module_run_platform

log_success "Tailscale module completed successfully!"
