#!/bin/bash
set -euo pipefail

# When invoked directly (not via the bootstrapper entrypoint), BOOTSTRAPPER_ROOT
# may not be set — derive it from this script's location.
: "${BOOTSTRAPPER_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export BOOTSTRAPPER_ROOT

source "$BOOTSTRAPPER_ROOT/core/_logging.sh"
source "$BOOTSTRAPPER_ROOT/core/_utils.sh"

perform_uninstall() {
  local BIN_DIR="$HOME/.local/bin"
  local INSTALL_DIR="$HOME/.local/share/bootstrapper"

  # ── Confirmation ───────────────────────────────────────────────────────────
  # Skip prompt when --yes / -y is passed or BOOTSTRAPPER_ASSUME_YES=1 is set.
  local assume_yes="${BOOTSTRAPPER_ASSUME_YES:-0}"
  for arg in "$@"; do
    [[ "$arg" == "--yes" || "$arg" == "-y" ]] && assume_yes=1
  done

  if [[ "$assume_yes" != "1" ]]; then
    log_warning "This will remove bootstrapper and all shell integration from your profiles."
    log_warning "Module-installed packages and binaries are NOT removed."
    if ! prompt_yes_no "Proceed with uninstall?" "n"; then
      log_info "Uninstall cancelled."
      return 0
    fi
  fi

  log_info "Uninstalling bootstrapper..."

  # ── 1. Remove the symlink ──────────────────────────────────────────────────
  local symlink="$BIN_DIR/bootstrapper"
  if [[ -L "$symlink" ]]; then
    log_info "Removing symlink: $symlink"
    rm -f "$symlink"
  elif [[ -e "$symlink" ]]; then
    log_warning "Skipping $symlink — not a symlink (will not remove)"
  fi

  # ── 2. Clean every detected shell profile ─────────────────────────────────
  for shell in $(detect_installed_shells); do
    local profile
    profile="$(get_shell_profile "$shell" 2>/dev/null)" || continue
    [[ -f "$profile" ]] || continue
    log_info "Cleaning profile: $profile"
    clean_profile "$profile" "$BIN_DIR"
  done

  # ── 3. Remove the clone ───────────────────────────────────────────────────
  # Only delete the canonical install location. If BOOTSTRAPPER_ROOT is a dev
  # checkout somewhere else, leave it in place so we don't nuke active work.
  if [[ "$BOOTSTRAPPER_ROOT" == "$INSTALL_DIR" ]]; then
    if [[ -d "$INSTALL_DIR" ]]; then
      log_info "Removing installation directory: $INSTALL_DIR"
      rm -rf "$INSTALL_DIR"
      # (Safe to rm -rf our own directory on Linux: the running process keeps the
      # inode alive until this shell exits, so the script continues cleanly.)
    fi
  else
    log_info "Dev checkout detected at $BOOTSTRAPPER_ROOT — leaving directory in place."
    log_info "(Only $INSTALL_DIR would be removed on a real install.)"
  fi

  # ── Done ──────────────────────────────────────────────────────────────────
  log_success "Bootstrapper uninstalled."
  log_info ""
  log_info "Open a new terminal (or run 'source <your-profile>') to clear the"
  log_info "bootstrapper function from your current shell session."
}

perform_uninstall "$@"
