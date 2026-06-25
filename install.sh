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
  __BOOTSTRAPPER_SHELL=zsh
  case "${ZSH_EVAL_CONTEXT:-}" in *:file*) __BOOTSTRAPPER_IS_SOURCED=1 ;; esac
else
  __BOOTSTRAPPER_SHELL=bash
  [ "${BASH_SOURCE[0]}" != "${0}" ] && __BOOTSTRAPPER_IS_SOURCED=1
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

  # Ensure BIN_DIR is on PATH so `bootstrapper` resolves for the eval below.
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) export PATH="$BIN_DIR:$PATH" ;;
  esac

  if [ "${__BOOTSTRAPPER_IS_SOURCED:-0}" = "1" ] && command -v bootstrapper >/dev/null 2>&1; then
    # Load the bootstrapper() wrapper function into the current shell.
    # The wrapper is what propagates PATH/export/alias from future module runs.
    eval "$(bootstrapper shellenv "${__BOOTSTRAPPER_SHELL:-bash}")"
    echo "bootstrapper is ready."
    echo -e "  Run: \033[0;34mbootstrapper help\033[0m"
  else
    # Not sourced (curl | bash): install succeeded but the parent shell won't
    # see PATH or the wrapper function.
    echo "bootstrapper installed."
    echo "Open a new terminal or run 'source ~/.bashrc' (or your shell's profile) to use it."
  fi
}

__bootstrapper_install
unset -f __bootstrapper_install 2>/dev/null || true
unset __BOOTSTRAPPER_IS_SOURCED __BOOTSTRAPPER_SHELL 2>/dev/null || true
