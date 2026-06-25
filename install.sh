#!/usr/bin/env bash
# Usage:
#   bash/zsh (recommended — bootstrapper usable immediately):
#     source <(curl -fsSL https://raw.githubusercontent.com/jleem99/bootstrapper/refs/heads/main/install.sh)
#
#   Fallback (curl | bash / bash install.sh) — installs but requires opening a new terminal:
#     curl -fsSL https://raw.githubusercontent.com/jleem99/bootstrapper/refs/heads/main/install.sh | bash

# Detect sourced vs executed at the TOP LEVEL of the file.
# Must be top-level: in zsh ZSH_EVAL_CONTEXT is "...:file" here but
# "...:file:shfunc" inside a function, so the check would fail if deferred.
__BOOTSTRAPPER_IS_SOURCED=0
if [ -n "${ZSH_VERSION:-}" ]; then
  case "${ZSH_EVAL_CONTEXT:-}" in *:file*) __BOOTSTRAPPER_IS_SOURCED=1 ;; esac
elif [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  __BOOTSTRAPPER_IS_SOURCED=1
fi

__bootstrapper_install() {
  local INSTALL_DIR="$HOME/.local/share/bootstrapper"
  local BIN_DIR="$HOME/.local/bin"
  local REPO="https://github.com/jleem99/bootstrapper.git"

  echo "Installing bootstrapper..."

  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing installation..."
    BOOTSTRAPPER_QUIET_HINT=1 bash "$INSTALL_DIR/bootstrapper" update \
      || { echo "Update failed." >&2; return 1; }
  else
    echo "Cloning repository..."
    git clone "$REPO" "$INSTALL_DIR" \
      || { echo "Clone failed." >&2; return 1; }
    echo "Initializing bootstrapper..."
    BOOTSTRAPPER_QUIET_HINT=1 bash "$INSTALL_DIR/bootstrapper" init \
      || { echo "Init failed." >&2; return 1; }
  fi

  # Apply PATH to the current shell — this is the entire point of sourcing.
  # When executed (curl | bash), this only affects the subprocess and is
  # effectively a no-op for the caller.
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) export PATH="$BIN_DIR:$PATH" ;;
  esac

  if [ "${__BOOTSTRAPPER_IS_SOURCED:-0}" = "1" ] && command -v bootstrapper >/dev/null 2>&1; then
    echo "bootstrapper is ready."
    echo -e "  Run: \033[0;34mbootstrapper help\033[0m"
  else
    echo "bootstrapper installed."
    echo "Open a new terminal or run 'source ~/.bashrc' (or your shell's profile) to use it."
  fi
}

__bootstrapper_install
unset -f __bootstrapper_install 2>/dev/null || true
unset __BOOTSTRAPPER_IS_SOURCED 2>/dev/null || true
