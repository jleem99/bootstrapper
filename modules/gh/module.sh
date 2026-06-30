#!/bin/bash
# Description: Install and authenticate GitHub CLI (gh)
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running gh module..."

module_run_platform

# ── Required scopes ───────────────────────────────────────────────────────────
# Default scopes granted by `gh auth login`: repo, read:org, gist
# Additional scope needed by the git module to upload SSH signing keys via API.
REQUIRED_SCOPES="admin:ssh_signing_key write:public_key"

# Returns 0 if all space-separated scopes in $1 are present in the token.
_gh_has_scopes() {
  local needed="$1"
  local current
  current="$(gh api -i user 2>/dev/null \
    | grep -i "^X-Oauth-Scopes:" \
    | cut -d':' -f2-)"
  for scope in $needed; do
    echo "$current" | grep -qw "$scope" || return 1
  done
  return 0
}

# ── Authentication ─────────────────────────────────────────────────────────────
if ! gh auth status &>/dev/null; then
  log_info "Authenticating with GitHub (requesting scopes: $REQUIRED_SCOPES)..."
  gh auth login -s "$REQUIRED_SCOPES"
elif ! _gh_has_scopes "$REQUIRED_SCOPES"; then
  log_info "Refreshing token to add missing scopes: $REQUIRED_SCOPES"
  gh auth refresh -h github.com -s "$REQUIRED_SCOPES"
else
  log_info "gh already authenticated with required scopes."
fi

log_success "gh module completed! $(gh --version | head -n1)"
