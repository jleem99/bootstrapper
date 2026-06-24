#!/bin/bash
set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"
TMUX_CONF="$HOME/.tmux.conf"

ensure_packages_installed tmux git

log_info "Installing TPM (Tmux Plugin Manager)..."
if [[ -d "$TPM_DIR" ]]; then
  log_info "TPM already present, pulling latest..."
  git -C "$TPM_DIR" pull --ff-only
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

log_info "Writing $TMUX_CONF..."
if [[ -f "$TMUX_CONF" ]]; then
  cp "$TMUX_CONF" "${TMUX_CONF}.bak"
  log_info "Existing config backed up to ${TMUX_CONF}.bak"
fi

cp "$(module_dir)/tmux.conf" "$TMUX_CONF"

log_info "Installing TPM plugins headlessly..."
"$TPM_DIR/scripts/install_plugins.sh" || log_info "Plugin install complete (non-zero exit is normal outside a tmux session)"

log_success "Tmux configured with TPM and all plugins installed."

if [[ -n "${TMUX:-}" ]]; then
  if prompt_yes_no "Apply config to the current tmux session now?"; then
    tmux source "$TMUX_CONF"
    log_success "Config reloaded."
  fi
else
  log_info "Not inside a tmux session — run 'tmux source ~/.tmux.conf' after starting tmux."
fi
