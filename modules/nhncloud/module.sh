#!/bin/bash
set -euo pipefail

log_info "Running nhncloud module..."

module_check_supported "nhncloud" "debian"
module_run_platform "nhncloud"

log_success "NHN Cloud module completed successfully!"
