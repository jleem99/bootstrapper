#!/bin/bash
set -euo pipefail

log_info "Running ngrok module..."

# Run platform-specific implementation
module_run_platform "ngrok"

log_success "ngrok module completed successfully!" 