#!/bin/bash
set -e

# Get the actual location of the bootstrapper script
BOOTSTRAPPER_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# Source the utils
source "$BOOTSTRAPPER_ROOT/core/_utils.sh"
source "$BOOTSTRAPPER_ROOT/core/_logging.sh"

# Installation directory
INSTALL_DIR="$HOME/.local/share/bootstrapper"
BIN_DIR="$HOME/.local/bin"

# Main initialization process
log_info "Initializing bootstrapper for $(get_current_shell)..."

# Create installation directories
mkdir -p "$BIN_DIR"

# Make the bootstrapper executable
chmod +x "$BOOTSTRAPPER_ROOT/bootstrapper"

# Create symlink to bootstrapper
ln -sf "$BOOTSTRAPPER_ROOT/bootstrapper" "$BIN_DIR/bootstrapper"

# Create shell profile if it doesn't exist
if [[ ! -f "$(get_shell_profile)" ]]; then
  log_info "Creating shell profile: $(get_shell_profile)"
  touch "$(get_shell_profile)"
fi

# Add to PATH
add_to_path "$BIN_DIR"

log_success "Bootstrapper initialized successfully!"
log_info "You can now run:"
log_info "  bootstrapper help" 