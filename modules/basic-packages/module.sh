#!/bin/bash
set -eu

log_info "Installing basic packages..."

# Define supported platforms
SUPPORTED_PLATFORMS=("debian" "macos")

# Check if the platform is supported
module_check_supported "basic-packages" "${SUPPORTED_PLATFORMS[@]}"

# Run platform-specific implementation
module_run_platform "basic-packages"

log_success "Basic packages installed successfully!" 