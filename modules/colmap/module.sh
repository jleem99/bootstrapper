#!/bin/bash
# Platforms: debian
set -euo pipefail

log_info "Installing COLMAP..."

# Run platform-specific implementation
module_run_platform

log_success "COLMAP installed successfully!"