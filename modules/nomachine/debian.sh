#!/bin/bash
set -euo pipefail

# ── Version pin (update both when bumping) ─────────────────────────────────────
NX_VERSION="9.7.3_1"
NX_BRANCH="9.7"

# ── Architecture mapping ───────────────────────────────────────────────────────
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  NX_ARCH="amd64";  NX_MD5="8af5efe7b8ad3872a4681c4acf551b62" ;;
  aarch64|arm64) NX_ARCH="arm64";  NX_MD5="" ;;  # no known sum for arm64
  *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

NX_PKG="nomachine_${NX_VERSION}_${NX_ARCH}.deb"
NX_URL="https://download.nomachine.com/download/${NX_BRANCH}/Linux/${NX_PKG}"

# ── Idempotency check ──────────────────────────────────────────────────────────
if [[ -x /usr/NX/bin/nxserver ]]; then
  log_info "NoMachine already installed: $(/usr/NX/bin/nxserver --version 2>&1 | head -1)"
else
  # ── Download ─────────────────────────────────────────────────────────────────
  ensure_packages_installed curl

  local tmp; tmp="$(mktemp -d)"
  local deb_path="$tmp/$NX_PKG"

  log_info "Downloading NoMachine $NX_VERSION ($NX_ARCH)..."
  curl -fsSL -o "$deb_path" "$NX_URL"

  # ── Optional MD5 integrity check ──────────────────────────────────────────────
  if [[ -n "$NX_MD5" ]]; then
    verify_md5() {
      echo "$NX_MD5  $deb_path" | md5sum -c --quiet
    }
    try_run "Verify MD5 checksum" verify_md5
  else
    log_warning "No known MD5 for $NX_ARCH — skipping checksum verification"
  fi

  # ── Install (apt resolves deps for a local .deb) ──────────────────────────────
  install_packages "$deb_path"

  rm -rf "$tmp"
fi
