#!/bin/bash
# Description: Install Claude Code CLI and restore user config (settings, MCP, global CLAUDE.md)
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running claude module..."

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

# ── Runtime dependencies ───────────────────────────────────────────────────────
log_section "Installing runtime dependencies"

# bun — required for claude-hud statusline and claude-mem plugin
run_module "bun"

# uv — required for the ouroboros MCP server (uvx --from ouroboros-ai[mcp,claude])
run_module "uv"

# codex CLI — required for the codex plugin
try_run "Install codex CLI"    bun install -g @openai/codex
try_run "Install claude-mem"   bunx claude-mem install

# ── Plugin marketplaces ────────────────────────────────────────────────────────
log_section "Registering plugin marketplaces"

try_run "Add claude-hud marketplace"   claude plugin marketplace add jarrodwatts/claude-hud
try_run "Add ouroboros marketplace"    claude plugin marketplace add Q00/ouroboros
try_run "Add claude-mem marketplace"   claude plugin marketplace add thedotmack/claude-mem
try_run "Add codex marketplace"        claude plugin marketplace add openai/codex-plugin-cc

# ── Plugins ───────────────────────────────────────────────────────────────────
log_section "Installing plugins"

try_run "Install claude-hud plugin" claude plugin install claude-hud@claude-hud --scope user
try_run "Install ouroboros plugin"  claude plugin install ouroboros@ouroboros   --scope user
try_run "Install claude-mem plugin" claude plugin install claude-mem@thedotmack --scope user
try_run "Install codex plugin"      claude plugin install codex@openai-codex    --scope user

# ── Done ───────────────────────────────────────────────────────────────────────
log_success "Claude module completed successfully!"
log_info ""
log_info "Manual steps required after running 'claude' and logging in:"
log_info "  /ouroboros:setup   — Guided onboarding wizard for Ouroboros"
log_info "  /codex:setup       — Check Codex CLI readiness and configure review gate"
log_info "  /claude-hud:setup  — Configure claude-hud as your statusline"
log_info ""
log_info "Open a new shell first to activate the alias, then run 'claude' to log in."
