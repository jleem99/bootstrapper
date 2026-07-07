#!/bin/bash
set -euo pipefail

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed curl

# ── NodeSource rpm setup script (auto-detects dnf/yum) ────────────────────────
curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" | sudo bash -

# ── Install ────────────────────────────────────────────────────────────────────
install_packages nodejs

log_success "Node.js $(node --version) installed via NodeSource"
