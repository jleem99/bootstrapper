#!/bin/bash
set -eu

log_info "Running example module..."

# Define supported platforms
SUPPORTED_PLATFORMS=("debian" "macos")

# Check if the platform is supported
module_check_supported "example" "${SUPPORTED_PLATFORMS[@]}"

# Run platform-specific implementation
module_run_platform "example"

log_success "Example module completed successfully!" 