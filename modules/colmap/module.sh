#!/bin/bash
set -eu

log_info "Installing COLMAP..."

# Define supported platforms
SUPPORTED_PLATFORMS=("debian")

# Check if platform is supported
check_platform_supported "${SUPPORTED_PLATFORMS[@]}"

# Run platform-specific implementation
run_platform_module "colmap"

log_success "COLMAP installed successfully!"