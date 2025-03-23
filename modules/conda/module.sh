#!/bin/bash
set -eu

log_info "Running conda module..."

# Define supported platforms
SUPPORTED_PLATFORMS=("debian" "macos")

# Check if the platform is supported
module_check_supported "conda" "${SUPPORTED_PLATFORMS[@]}"

# Run platform-specific implementation
module_run_platform "conda"

log_success "conda module completed successfully!" 