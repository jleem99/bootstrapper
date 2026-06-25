#!/bin/bash
# Description: Install the Bun JavaScript runtime
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running bun module..."

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed "curl" "unzip"

# ── Install Bun ───────────────────────────────────────────────────────────────
BUN_BIN_DIR="$HOME/.bun/bin"

if command -v bun &>/dev/null; then
  log_info "Bun is already installed: $(bun --version)"
else
  log_info "Installing Bun..."
  install_bun() {
    curl -fsSL https://bun.sh/install | bash
  }
  try_run "Install Bun" install_bun
fi

# Ensure ~/.bun/bin is on PATH for subsequent steps in the current run
mkdir -p "$BUN_BIN_DIR"
add_to_path "$BUN_BIN_DIR"

log_success "Bun module completed successfully!"
