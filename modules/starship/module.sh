#!/bin/bash
# Description: Install Starship cross-shell prompt
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running starship module..."

ensure_packages_installed "curl"

install_starship() {
  curl -sS https://starship.rs/install.sh | POSIXLY_CORRECT=1 sh -s -- --yes
}
try_run "Install Starship" install_starship

# Only write init lines if the binary actually installed; on environments with
# an incompatible version/libc the installer can fail and the binary won't be
# present, which would cause "starship: command not found" on every shell start.
if command -v starship &>/dev/null; then
  for _shell in $(detect_installed_shells); do
    _profile="$(get_shell_profile "$_shell" 2>/dev/null)" || continue
    [[ -f "$_profile" ]] || continue

    case "$_shell" in
      bash|zsh)
        if ! grep -q "starship init $_shell" "$_profile"; then
          echo "eval \"\$(starship init $_shell)\"" >> "$_profile"
        fi
        ;;
      fish)
        if ! grep -q "starship init fish" "$_profile"; then
          echo 'starship init fish | source' >> "$_profile"
        fi
        ;;
    esac
  done
  log_success "Starship $(starship --version) configured for all detected shells"
else
  log_warning "starship not found after install — skipping shell init lines"
fi

log_success "Starship module completed!"
