#!/bin/bash
set -euo pipefail

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed ca-certificates curl gnupg

# ── NodeSource GPG keyring ─────────────────────────────────────────────────────
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg

# ── NodeSource apt repository ──────────────────────────────────────────────────
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] \
https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
  | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null

# ── Install ────────────────────────────────────────────────────────────────────
update_package_manager
install_packages nodejs

log_success "Node.js $(node --version) installed via NodeSource"
