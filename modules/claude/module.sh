#!/bin/bash
# Description: Install Claude Code CLI and restore user config (settings, MCP, global CLAUDE.md)
set -euo pipefail

log_info "Running claude module..."

module_check_supported "claude" "debian" "fedora" "rhel" "arch" "macos"

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed "curl" "git"

# ── Install CLI ────────────────────────────────────────────────────────────────
if command -v claude &>/dev/null; then
  log_info "Claude Code is already installed: $(claude --version 2>/dev/null || echo '(version unknown)')"
else
  log_info "Installing Claude Code (native installer)..."
  install_claude_cli() {
    curl -fsSL https://claude.ai/install.sh | bash
  }
  try_run "Install Claude Code CLI" install_claude_cli
fi

# Ensure ~/.local/bin is on PATH (the native installer places the symlink there)
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
add_to_path "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# ── Restore config files ───────────────────────────────────────────────────────
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

CONFIG_SRC="$(module_dir)/config"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Helper: copy a config file, backing up and prompting if a different file exists
install_config() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [[ -f "$dst" ]]; then
    if diff -q "$src" "$dst" &>/dev/null; then
      log_info "$label is already up-to-date, skipping."
      return
    fi
    log_warning "Existing $label differs from the bundled template."
    if prompt_yes_no "Overwrite $dst with the bundled $label?" "n"; then
      cp "$dst" "${dst}.bak-${TIMESTAMP}"
      log_info "Backed up existing file to ${dst}.bak-${TIMESTAMP}"
      cp "$src" "$dst"
      log_success "Restored $label"
    else
      log_info "Keeping existing $label unchanged."
    fi
  else
    cp "$src" "$dst"
    log_success "Installed $label to $dst"
  fi
}

install_config "$CONFIG_SRC/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
install_config "$CONFIG_SRC/mcp.json"      "$CLAUDE_DIR/mcp.json"      "mcp.json"
install_config "$CONFIG_SRC/CLAUDE.md"     "$CLAUDE_DIR/CLAUDE.md"     "CLAUDE.md"

# ── Alias ──────────────────────────────────────────────────────────────────────
add_alias "claude" "claude --dangerously-skip-permissions"

# ── Done ───────────────────────────────────────────────────────────────────────
log_success "Claude module completed successfully!"
log_info ""
log_info "Next steps:"
log_info "  1. Open a new shell (or source your profile) to activate the alias."
log_info "  2. Run 'claude' once to authenticate — credentials are per-machine."
log_info "  3. Enabled plugins (claude-hud, claude-mem, ouroboros, codex) install"
log_info "     automatically from GitHub on first launch."
