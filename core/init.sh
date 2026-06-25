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

# Snapshot PATH before add_to_path mutates it — used below to decide whether
# we need to tell the user how to activate bootstrapper in their current shell.
_PATH_BEFORE="$PATH"

add_to_path "$BIN_DIR" "$SHELL_NAME"

# Write (or refresh) the bootstrapper() wrapper function in the profile so that
# new shells load it. The function is the shell-function wrapper: it runs the
# binary as a subprocess but sources the env-delta file afterward, propagating
# PATH/export/alias changes to the calling interactive shell.
# update.sh calls `bootstrapper init`, so this block is refreshed on update too.
log_info "Writing bootstrapper shell function to $PROFILE"
write_managed_block "$PROFILE" "$(print_shellenv "$SHELL_NAME")"

log_success "Bootstrapper initialized successfully!"

# BOOTSTRAPPER_QUIET_HINT=1 is set by install.sh/install.fish so the activation
# hint is suppressed when the sourced installer applies PATH directly to the
# caller's shell. Keep the hint for standalone `bootstrapper init` runs.
if [[ -z "${BOOTSTRAPPER_QUIET_HINT:-}" ]]; then
  case ":$_PATH_BEFORE:" in
    *":$BIN_DIR:"*)
      log_info "Run 'bootstrapper help' to get started."
      ;;
    *)
      log_info ""
      log_info "To use 'bootstrapper' in your current shell, run:"
      log_info "  source $PROFILE"
      log_info "Or open a new terminal."
      ;;
  esac
fi
