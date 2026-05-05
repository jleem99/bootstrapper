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

ensure_packages_installed curl tar

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
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL_URL="https://pkgs.tailscale.com/stable/tailscale_latest_${ARCH}.tgz"
curl -fsSL "$TARBALL_URL" -o "$TMP_DIR/tailscale.tgz"
tar -xzf "$TMP_DIR/tailscale.tgz" -C "$TMP_DIR"

EXTRACT_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name "tailscale_*_${ARCH}" | head -n 1)"
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

log_info "Writing $SYSTEMD_USER_DIR/$SERVICE_NAME..."
cat > "$SYSTEMD_USER_DIR/$SERVICE_NAME" <<'EOF'
[Unit]
Description=Tailscale userspace node agent
Documentation=https://tailscale.com/docs/
After=default.target

[Service]
Type=notify
EnvironmentFile=-%h/.config/tailscale/tailscaled.env
ExecStartPre=/usr/bin/mkdir -p %t/tailscale %h/.local/state/tailscale %h/.cache/tailscale
ExecStart=%h/.local/bin/tailscaled \
  --tun=userspace-networking \
  --state=%h/.local/state/tailscale/tailscaled.state \
  --socket=%t/tailscale/tailscaled.sock \
  --port=${PORT} \
  $FLAGS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]] && ! grep -q '^ts() {' "$ZSHRC"; then
  log_info "Appending ts() helper function to $ZSHRC..."
  cat >> "$ZSHRC" <<'EOF'

ts() {
  "$HOME/.local/bin/tailscale" \
    --socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tailscale/tailscaled.sock" \
    "$@"
}
EOF
else
  log_info "ts() helper already present in $ZSHRC (or no .zshrc) — skipping"
fi

log_info "Enabling user-manager linger so the daemon survives logout..."
loginctl enable-linger "$USER"

log_info "Reloading user systemd and starting $SERVICE_NAME..."
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME"

log_success "Tailscale userspace daemon installed and running."
log_info ""
log_info "Next steps (run in a new zsh shell, or after 'source ~/.zshrc'):"
log_info "  ts up --login-server=$LOGIN_SERVER"
log_info "  ts status"
