#!/bin/bash
set -euo pipefail

# ── Ensure Homebrew is available ───────────────────────────────────────────────
ensure_homebrew

# ── Install ────────────────────────────────────────────────────────────────────
install_packages "node@${NODE_MAJOR}"

# node@22 is keg-only — add its bin dir to PATH for this session and all shells
NODE_BIN_DIR="$(brew --prefix)/opt/node@${NODE_MAJOR}/bin"
add_to_path "$NODE_BIN_DIR"

log_success "Node.js $(node --version) installed via Homebrew (node@${NODE_MAJOR})"
