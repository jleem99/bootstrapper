#!/bin/bash
# Platforms: debian macos
set -euo pipefail

log_info "Running example module..."

# Run platform-specific implementation
module_run_platform

log_success "Example module completed successfully!" 