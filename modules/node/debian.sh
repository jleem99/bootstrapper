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
