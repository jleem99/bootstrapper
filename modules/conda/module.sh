#!/bin/bash
# Platforms: debian macos
set -euo pipefail

log_info "Running conda module..."

# Run platform-specific implementation
module_run_platform

log_success "conda module completed successfully!" 