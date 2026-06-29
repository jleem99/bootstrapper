#!/bin/bash
set -euo pipefail

# ── Idempotency ────────────────────────────────────────────────────────────────
if command -v gh &>/dev/null; then
  log_info "gh already installed: $(gh --version | head -n1)"
  return 0 2>/dev/null || exit 0
fi

# ── Install ────────────────────────────────────────────────────────────────────
# Package is named 'github-cli' in the Arch extra repo.
ensure_packages_installed github-cli

log_success "gh $(gh --version | head -n1) installed"
