#!/bin/bash
set -euo pipefail

# ── Idempotency ────────────────────────────────────────────────────────────────
if command -v gh &>/dev/null; then
  log_info "gh already installed: $(gh --version | head -n1)"
  return 0 2>/dev/null || exit 0
fi

# ── Install ────────────────────────────────────────────────────────────────────
# Try direct install first (works on RHEL 9+ with EPEL); fall back to the
# official rpm repo if dnf cannot resolve the package.
if ! sudo dnf install -y gh 2>/dev/null; then
  log_info "gh not found in default repos; adding GitHub CLI rpm repo..."
  sudo dnf install -y 'dnf-command(config-manager)'
  sudo dnf config-manager --add-repo \
    https://cli.github.com/packages/rpm/gh-cli.repo
  sudo dnf install -y gh
fi

log_success "gh $(gh --version | head -n1) installed"
