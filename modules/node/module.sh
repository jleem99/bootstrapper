#!/bin/bash
# Description: Install system Node.js (LTS 22) and npm
# Platforms: debian fedora rhel macos
set -euo pipefail

log_info "Running node module..."

module_run_platform

log_success "Node module completed! node $(node --version 2>/dev/null) / npm $(npm --version 2>/dev/null)"
