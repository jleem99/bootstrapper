#!/bin/bash
set -euo pipefail

# ── Neovim binary (official tarball → /opt) ────────────────────────────────────
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  NVIM_DIR="nvim-linux-x86_64" ;;
  aarch64|arm64) NVIM_DIR="nvim-linux-arm64" ;;
  *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

if command -v nvim &>/dev/null; then
  log_info "Neovim already installed: $(nvim --version | head -1)"
else
  install_nvim() {
    local tmp; tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/nvim.tar.gz" \
      "https://github.com/neovim/neovim/releases/latest/download/${NVIM_DIR}.tar.gz"
    sudo rm -rf "/opt/${NVIM_DIR}"
    sudo tar -C /opt -xzf "$tmp/nvim.tar.gz"
    rm -rf "$tmp"
  }
  try_run "Install Neovim" install_nvim
fi

# Ensure nvim is on PATH for the config restore + headless sync that follows
add_to_path "/opt/${NVIM_DIR}/bin"
export PATH="/opt/${NVIM_DIR}/bin:$PATH"

# ── LazyVim system deps ────────────────────────────────────────────────────────
# Note: apt package names differ from command names:
#   ripgrep (rg), fd-find (fdfind), build-essential (gcc/make)
install_packages "ripgrep" "fd-find" "build-essential" "unzip" "git" "curl"
