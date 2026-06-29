#!/bin/bash
set -euo pipefail

# ── Idempotency ────────────────────────────────────────────────────────────────
if command -v gh &>/dev/null; then
  log_info "gh already installed: $(gh --version | head -n1)"
  return 0 2>/dev/null || exit 0
fi

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed ca-certificates curl sudo

# ── GitHub CLI GPG keyring ────────────────────────────────────────────────────
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg

sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

# ── GitHub CLI apt repository ─────────────────────────────────────────────────
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# ── Install ────────────────────────────────────────────────────────────────────
update_package_manager
install_packages gh

log_success "gh $(gh --version | head -n1) installed"
