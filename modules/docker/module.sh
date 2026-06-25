#!/bin/bash
# Platforms: debian
set -euo pipefail

log_info "Running docker module..."

# Run platform-specific implementation
module_run_platform

log_success "Docker module completed successfully!" 