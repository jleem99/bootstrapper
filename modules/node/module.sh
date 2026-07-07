#!/bin/bash
# Description: Install system Node.js (LTS 22) and npm
# Platforms: debian fedora rhel macos
set -euo pipefail

log_info "Running node module..."

NODE_MAJOR=22

# ── Idempotency ────────────────────────────────────────────────────────────────
if command -v node &>/dev/null; then
  installed_major="$(node --version | sed 's/v\([0-9]*\).*/\1/')"
  if [[ "$installed_major" == "$NODE_MAJOR" ]]; then
    log_info "Node.js ${NODE_MAJOR}.x already installed: $(node --version)"
    return 0 2>/dev/null || exit 0
  fi
fi

module_run_platform

log_success "Node module completed! node $(node --version 2>/dev/null) / npm $(npm --version 2>/dev/null)"
