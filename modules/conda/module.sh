#!/bin/bash
set -eu

log_info "Running conda module..."

# Run platform-specific implementation
module_run_platform "conda"

log_success "conda module completed successfully!" 