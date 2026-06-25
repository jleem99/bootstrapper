#!/bin/bash
# Platforms: debian
set -euo pipefail

log_info "Setting up VNC server..."

# Run platform-specific implementation
module_run_platform

log_success "VNC server setup completed successfully!" 