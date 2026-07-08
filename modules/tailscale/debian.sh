#!/bin/bash
set -euo pipefail

LOGIN_SERVER="https://hs.example.com"
SERVICE_NAME="tailscale-userspace.service"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/tailscale"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
STATE_DIR="$HOME/.local/state/tailscale"
CACHE_DIR="$HOME/.cache/tailscale"
LEGACY_STATE="$HOME/.local/share/tailscale/tailscaled.state"

# `systemctl --user` / `loginctl` talk to the per-user D-Bus session at
# $XDG_RUNTIME_DIR/bus. Non-login shells (su, provisioning/agent contexts, etc.)
# often don't set XDG_RUNTIME_DIR, which makes those calls silently no-op with
# "Failed to connect to bus: No medium found" instead of failing loudly.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

ensure_packages_installed curl

log_info "Detecting CPU architecture..."
case "$(uname -m)" in
  x86_64)        ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    log_error "Unsupported architecture: $(uname -m)"
    exit 1
    ;;
esac
log_info "Architecture: $ARCH"

log_info "Stopping existing $SERVICE_NAME (if running)..."
systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true

log_info "Downloading latest Tailscale static tarball..."
TARBALL_URL="https://pkgs.tailscale.com/stable/tailscale_latest_${ARCH}.tgz"
download_and_extract "$TARBALL_URL" EXTRACT_ROOT

EXTRACT_DIR="$(find "$EXTRACT_ROOT" -maxdepth 1 -type d -name "tailscale_*_${ARCH}" | head -n 1)"
if [[ -z "$EXTRACT_DIR" || ! -f "$EXTRACT_DIR/tailscale" || ! -f "$EXTRACT_DIR/tailscaled" ]]; then
  log_error "Tarball did not contain expected tailscale/tailscaled binaries"
  exit 1
fi

log_info "Installing binaries to $BIN_DIR..."
mkdir -p "$BIN_DIR"
install -m 0755 "$EXTRACT_DIR/tailscale" "$BIN_DIR/tailscale"
install -m 0755 "$EXTRACT_DIR/tailscaled" "$BIN_DIR/tailscaled"

log_info "Creating user config / state / cache directories..."
mkdir -p "$SYSTEMD_USER_DIR" "$CONFIG_DIR" "$STATE_DIR" "$CACHE_DIR"

if [[ -f "$LEGACY_STATE" && ! -f "$STATE_DIR/tailscaled.state" ]]; then
  log_info "Migrating legacy state from $LEGACY_STATE to $STATE_DIR/tailscaled.state"
  cp "$LEGACY_STATE" "$STATE_DIR/tailscaled.state"
fi

log_info "Writing $CONFIG_DIR/tailscaled.env..."
cat > "$CONFIG_DIR/tailscaled.env" <<'EOF'
PORT=0
FLAGS=--socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055
EOF

log_info "Installing $SYSTEMD_USER_DIR/$SERVICE_NAME..."
install -m 0644 "$(module_dir)/tailscale-userspace.service" "$SYSTEMD_USER_DIR/$SERVICE_NAME"

# Ensure ~/.local/bin is on PATH and register the ts() shortcut across every
# detected shell profile (not just zsh) via the shared alias utility.
add_to_path "$BIN_DIR"
add_alias "ts" "tailscale --socket=\$XDG_RUNTIME_DIR/tailscale/tailscaled.sock"

log_info "Enabling user-manager linger so the daemon survives logout..."
loginctl enable-linger "$USER"

log_info "Reloading user systemd and starting $SERVICE_NAME..."
systemctl --user daemon-reload
if ! systemctl --user enable --now "$SERVICE_NAME"; then
  log_error "Failed to start $SERVICE_NAME (is XDG_RUNTIME_DIR / user bus available?)"
  exit 1
fi

log_success "Tailscale userspace daemon installed and running."
log_info ""
log_info "Next steps (run in a new shell, or after 'source $(get_shell_profile)'):"
log_info "  ts up --login-server=$LOGIN_SERVER"
log_info "  ts status"
