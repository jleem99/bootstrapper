#!/bin/bash
set -euo pipefail

SHELL_NAME="${1:-$(get_current_shell)}"
BIN_DIR="$HOME/.local/bin"

log_info "Initializing bootstrapper for $SHELL_NAME..."

mkdir -p "$BIN_DIR"
chmod +x "$BOOTSTRAPPER_ROOT/bootstrapper"
ln -sf "$BOOTSTRAPPER_ROOT/bootstrapper" "$BIN_DIR/bootstrapper"

PROFILE="$(get_shell_profile "$SHELL_NAME")"
if [[ ! -f "$PROFILE" ]]; then
  log_info "Creating shell profile: $PROFILE"
  touch "$PROFILE"
fi

add_to_path "$BIN_DIR" "$SHELL_NAME"
export PATH="$BIN_DIR:$PATH"

log_success "Bootstrapper initialized successfully!"
