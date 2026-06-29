#!/bin/bash
set -euo pipefail

NODE_MAJOR=22

# ── Ensure Homebrew is available ───────────────────────────────────────────────
ensure_homebrew

# ── Idempotency ────────────────────────────────────────────────────────────────
if command -v node &>/dev/null; then
  installed_major="$(node --version | sed 's/v\([0-9]*\).*/\1/')"
  if [[ "$installed_major" == "$NODE_MAJOR" ]]; then
    log_info "Node.js ${NODE_MAJOR}.x already installed: $(node --version)"
    return 0 2>/dev/null || exit 0
  fi
fi

# ── Install ────────────────────────────────────────────────────────────────────
install_packages "node@${NODE_MAJOR}"

# node@22 is keg-only — add its bin dir to PATH for this session and all shells
NODE_BIN_DIR="$(brew --prefix)/opt/node@${NODE_MAJOR}/bin"
add_to_path "$NODE_BIN_DIR"

log_success "Node.js $(node --version) installed via Homebrew (node@${NODE_MAJOR})"
