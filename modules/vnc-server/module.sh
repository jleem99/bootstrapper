#!/bin/bash
set -eu

log_info "Setting up VNC server..."

# Source platform detection module
source "$BOOTSTRAPPER_ROOT/core/_platform.sh"

# Define supported platforms
SUPPORTED_PLATFORMS=("debian")

# Check if platform is supported
check_platform_supported "${SUPPORTED_PLATFORMS[@]}"

# Run platform-specific implementation
run_platform_module "vnc-server"

log_success "VNC server setup completed successfully!" 