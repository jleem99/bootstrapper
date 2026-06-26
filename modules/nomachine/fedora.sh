#!/bin/bash
set -euo pipefail

# ── Version pin (update both when bumping) ─────────────────────────────────────
NX_VERSION="9.7.3_1"
NX_BRANCH="9.7"

# ── Architecture mapping ───────────────────────────────────────────────────────
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  NX_ARCH="x86_64"; NX_MD5="d3b3605b65d8931a200ffce520fd7789" ;;
  aarch64|arm64) NX_ARCH="aarch64"; NX_MD5="" ;;  # no known sum for arm64
  *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

NX_PKG="nomachine_${NX_VERSION}_${NX_ARCH}.rpm"
NX_URL="https://download.nomachine.com/download/${NX_BRANCH}/Linux/${NX_PKG}"

# ── Idempotency check ──────────────────────────────────────────────────────────
if [[ -x /usr/NX/bin/nxserver ]]; then
  log_info "NoMachine already installed: $(/usr/NX/bin/nxserver --version 2>&1 | head -1)"
else
  # ── Download ─────────────────────────────────────────────────────────────────
  ensure_packages_installed curl

  local tmp; tmp="$(mktemp -d)"
  local rpm_path="$tmp/$NX_PKG"

  log_info "Downloading NoMachine $NX_VERSION ($NX_ARCH)..."
  curl -fsSL -o "$rpm_path" "$NX_URL"

  # ── Optional MD5 integrity check ──────────────────────────────────────────────
  if [[ -n "$NX_MD5" ]]; then
    verify_md5() {
      echo "$NX_MD5  $rpm_path" | md5sum -c --quiet
    }
    try_run "Verify MD5 checksum" verify_md5
  else
    log_warning "No known MD5 for $NX_ARCH — skipping checksum verification"
  fi

  # ── Install (dnf/yum both accept a local .rpm path) ──────────────────────────
  install_packages "$rpm_path"

  rm -rf "$tmp"
fi
