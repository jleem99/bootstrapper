#!/bin/bash
set -euo pipefail

NODE_MAJOR=22

# ── Idempotency ────────────────────────────────────────────────────────────────
if command -v node &>/dev/null; then
  installed_major="$(node --version | sed 's/v\([0-9]*\).*/\1/')"
  if [[ "$installed_major" == "$NODE_MAJOR" ]]; then
    log_info "Node.js ${NODE_MAJOR}.x already installed: $(node --version)"
    return 0 2>/dev/null || exit 0
  fi
fi

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed curl

# ── NodeSource rpm setup script (auto-detects dnf/yum) ────────────────────────
curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" | sudo bash -

# ── Install ────────────────────────────────────────────────────────────────────
install_packages nodejs

log_success "Node.js $(node --version) installed via NodeSource"
