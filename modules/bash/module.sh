#!/bin/bash
# Description: Install oh-my-bash, ble.sh (highlighting + autosuggestions), and Starship prompt
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running bash module..."

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed "bash" "curl" "git"

# Default shell to bash (usually already true; non-fatal in sandboxes)
try_run "Set default shell to bash" chsh -s "$(which bash)"

# ── oh-my-bash ─────────────────────────────────────────────────────────────────
# --unattended means: install without dropping into a new interactive session.
# The installer backs up ~/.bashrc to ~/.bashrc.omb-backup-<timestamp> and
# replaces it with a template, so this must run before we append to ~/.bashrc.
if [[ ! -d "$HOME/.oh-my-bash" ]]; then
  log_info "Installing oh-my-bash..."
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
else
  log_info "oh-my-bash already installed, skipping."
fi

# ── ble.sh (syntax highlighting + autosuggestions) ─────────────────────────────
install_blesh() {
  if [[ ! -e "$HOME/.local/share/blesh/ble.sh" ]]; then
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
      | tar -xJf - -C "$tmp"
    bash "$tmp/ble-nightly/ble.sh" --install "$HOME/.local/share"
    rm -rf "$tmp"
  else
    log_info "ble.sh already installed, skipping."
  fi
  # Append source line if not already present
  if ! grep -q "blesh/ble.sh" "$HOME/.bashrc"; then
    echo '[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh' >> "$HOME/.bashrc"
  fi
}
try_run "Install ble.sh" install_blesh

# ── Starship prompt ─────────────────────────────────────────────────────────────
run_module "starship"

# ── PATH ───────────────────────────────────────────────────────────────────────
add_to_path "$HOME/.local/bin" bash

log_success "bash module completed successfully!"
