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

# Determine shell type from argument or $SHELL
CURRENT_SHELL="$1"
if [[ -z "$CURRENT_SHELL" ]]; then
  case "$SHELL" in
    */bash)
      CURRENT_SHELL="bash"
      ;;
    */zsh)
      CURRENT_SHELL="zsh"
      ;;
    */fish)
      CURRENT_SHELL="fish"
      ;;
    *)
      log_error "Unsupported or unknown shell: $SHELL"
      log_info "Please specify your shell type as an argument:"
      log_info "  $0 bash|zsh|fish"
      exit 1
      ;;
  esac
fi

# Main initialization process
log_info "Initializing bootstrapper for $CURRENT_SHELL..."

# Create installation directories
mkdir -p "$BIN_DIR"

# Make the bootstrapper executable
chmod +x "$BOOTSTRAPPER_ROOT/bootstrapper"

# Create symlink to bootstrapper
ln -sf "$BOOTSTRAPPER_ROOT/bootstrapper" "$BIN_DIR/bootstrapper"

# Get shell profile
SHELL_PROFILE=$(get_shell_profile "$CURRENT_SHELL")

# Create shell profile if it doesn't exist
if [[ ! -f "$SHELL_PROFILE" ]]; then
  log_info "Creating shell profile: $SHELL_PROFILE"
  touch "$SHELL_PROFILE"
fi

# Add to PATH
add_to_path "$CURRENT_SHELL" "$BIN_DIR" "$SHELL_PROFILE"

log_success "Bootstrapper initialized successfully!"
log_info "To start using bootstrapper immediately, run:"
log_info "  source $SHELL_PROFILE"
log_info "Or restart your terminal, then run:"
log_info "  bootstrapper help" 