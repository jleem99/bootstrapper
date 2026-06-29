#!/bin/bash
set -euo pipefail

# ── Idempotency ────────────────────────────────────────────────────────────────
if command -v gh &>/dev/null; then
  log_info "gh already installed: $(gh --version | head -n1)"
  return 0 2>/dev/null || exit 0
fi

# ── Install ────────────────────────────────────────────────────────────────────
# gh is available in the official Fedora repos (Fedora 36+).
ensure_packages_installed gh

log_success "gh $(gh --version | head -n1) installed"
