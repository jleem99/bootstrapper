#!/bin/bash
set -eu

log_info "Installing basic packages..."

# Run platform-specific implementation
module_run_platform "basic-packages"

log_success "Basic packages installed successfully!" 