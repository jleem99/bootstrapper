#!/bin/bash
# Description: Install the uv Python package manager
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running uv module..."

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed "curl"

# ── Install uv ────────────────────────────────────────────────────────────────
UV_BIN_DIR="$HOME/.local/bin"

if command -v uv &>/dev/null; then
  log_info "uv is already installed: $(uv --version)"
else
  log_info "Installing uv..."
  install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
  }
  try_run "Install uv" install_uv
fi

# Ensure ~/.local/bin is on PATH for subsequent steps in the current run
mkdir -p "$UV_BIN_DIR"
add_to_path "$UV_BIN_DIR"

log_success "uv module completed successfully!"
