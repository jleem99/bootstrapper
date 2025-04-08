#!/bin/bash
set -euo pipefail

log_info "Setting up VNC server..."

# Run platform-specific implementation
run_platform_module "vnc-server"

log_success "VNC server setup completed successfully!" 