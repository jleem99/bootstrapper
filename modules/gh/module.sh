#!/bin/bash
# Description: Install and authenticate GitHub CLI (gh)
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running gh module..."

module_run_platform

# ── Authentication ─────────────────────────────────────────────────────────────
if gh auth status &>/dev/null; then
  log_info "gh already authenticated: $(gh auth status 2>&1 | head -n1)"
else
  log_info "Authenticating with GitHub..."
  gh auth login
fi

log_success "gh module completed! $(gh --version | head -n1)"
