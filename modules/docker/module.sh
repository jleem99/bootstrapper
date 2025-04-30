#!/bin/bash
set -euo pipefail

log_info "Running docker module..."

# Run platform-specific implementation
module_run_platform "docker"

log_success "Docker module completed successfully!" 