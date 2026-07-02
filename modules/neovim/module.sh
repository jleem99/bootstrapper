#!/bin/bash
# Description: Install Neovim + LazyVim config (plugins, deps, headless sync)
# Platforms: debian macos
set -euo pipefail

log_info "Running neovim module..."

# ── Binary + system deps (platform-specific) ───────────────────────────────────
module_run_platform

# ── Restore LazyVim config ─────────────────────────────────────────────────────
NVIM_CONFIG="$HOME/.config/nvim"
CONFIG_SRC="$(module_dir)/config"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if [[ -d "$NVIM_CONFIG" ]]; then
  log_warning "Existing Neovim config found at $NVIM_CONFIG"
  if prompt_yes_no "Back up and replace it with the bundled LazyVim config?" "n"; then
    mv "$NVIM_CONFIG" "${NVIM_CONFIG}.bak-${TIMESTAMP}"
    log_info "Backed up existing config to ${NVIM_CONFIG}.bak-${TIMESTAMP}"
    mkdir -p "$NVIM_CONFIG"
    cp -r "$CONFIG_SRC/." "$NVIM_CONFIG/"
    log_success "Restored Neovim config"
  else
    log_info "Keeping existing Neovim config unchanged."
  fi
else
  mkdir -p "$NVIM_CONFIG"
  cp -r "$CONFIG_SRC/." "$NVIM_CONFIG/"
  log_success "Installed Neovim config to $NVIM_CONFIG"
fi

# ── Alias vi to nvim ────────────────────────────────────────────────────────────
add_alias "vi" "nvim"

# ── Pre-install plugins at locked versions (non-fatal) ─────────────────────────
if command -v nvim &>/dev/null; then
  try_run "Install Neovim plugins (Lazy restore)" \
    nvim --headless "+Lazy! restore" +qa < /dev/null
else
  log_warning "nvim not on PATH yet — open a new shell and run nvim to finish setup."
fi

log_success "Neovim module completed successfully!"
log_info "Open a new shell, then run 'nvim'. Mason LSPs install on demand."
