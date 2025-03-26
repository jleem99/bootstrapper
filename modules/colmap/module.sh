#!/bin/bash
set -eu

log_info "Installing COLMAP..."

# Run platform-specific implementation
run_platform_module "colmap"

log_success "COLMAP installed successfully!"