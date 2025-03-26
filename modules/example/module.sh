#!/bin/bash
set -eu

log_info "Running example module..."

# Run platform-specific implementation
module_run_platform "example"

log_success "Example module completed successfully!" 