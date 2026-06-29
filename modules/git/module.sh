#!/bin/bash
# Description: Configure git with aliases, SSH commit signing, and GitHub identity
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running git module..."

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed git git-lfs

# ── GitHub CLI: install + authenticate ────────────────────────────────────────
run_module "gh"

# ── Derive identity from GitHub ───────────────────────────────────────────────
log_info "Fetching identity from GitHub API..."

_gh_name=""
_gh_email=""
_gh_id=""
_gh_login=""

if gh auth status &>/dev/null; then
  _gh_name="$(gh api user --jq '.name // .login' 2>/dev/null || true)"
  _gh_email="$(gh api user --jq '.email // ""' 2>/dev/null || true)"
  _gh_id="$(gh api user --jq '.id' 2>/dev/null || true)"
  _gh_login="$(gh api user --jq '.login' 2>/dev/null || true)"

  # GitHub may return null for email (private profile); fall back to noreply address
  if [[ -z "$_gh_email" || "$_gh_email" == "null" ]]; then
    _gh_email="${_gh_id}+${_gh_login}@users.noreply.github.com"
    log_info "GitHub email is private — using noreply address: $_gh_email"
  fi
else
  log_warning "gh authentication unavailable — falling back to manual entry"
  # Fall back to any existing config values
  _gh_name="$(git config --global user.name 2>/dev/null || true)"
  _gh_email="$(git config --global user.email 2>/dev/null || true)"
fi

log_info "Detected identity:"
log_info "  name  : $_gh_name"
log_info "  email : $_gh_email"

if prompt_yes_no "Use these for git identity?" "y"; then
  GIT_NAME="$_gh_name"
  GIT_EMAIL="$_gh_email"
else
  read -r -p "Git user.name [${_gh_name}]: " GIT_NAME
  GIT_NAME="${GIT_NAME:-$_gh_name}"
  read -r -p "Git user.email [${_gh_email}]: " GIT_EMAIL
  GIT_EMAIL="${GIT_EMAIL:-$_gh_email}"
fi

if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
  log_error "Git user.name and user.email must not be empty."
  exit 1
fi

# ── Install gitconfig template ─────────────────────────────────────────────────
GITCONFIG="$HOME/.gitconfig"
TEMPLATE="$(module_dir)/gitconfig"

if [[ -f "$GITCONFIG" ]]; then
  if ! diff -q "$TEMPLATE" "$GITCONFIG" &>/dev/null; then
    BACKUP="${GITCONFIG}.bak-$(date +%Y%m%d%H%M%S)"
    cp "$GITCONFIG" "$BACKUP"
    log_info "Existing ~/.gitconfig backed up to $BACKUP"
  else
    log_info "~/.gitconfig already matches template — skipping copy"
  fi
fi
cp "$TEMPLATE" "$GITCONFIG"
log_success "~/.gitconfig installed from template"

# ── Generate signing key: id_git ──────────────────────────────────────────────
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/id_git"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

_generate_key=true
if [[ -f "$KEY_PATH" ]]; then
  log_warning "SSH signing key $KEY_PATH already exists."
  if ! prompt_yes_no "Regenerate id_git?" "n"; then
    log_info "Keeping existing id_git key."
    _generate_key=false
  fi
fi

if [[ "$_generate_key" == true ]]; then
  ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$GIT_EMAIL" -N ""
  log_success "Generated $KEY_PATH (ed25519)"
fi

# ── Write identity + signing config ──────────────────────────────────────────
git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global user.signingkey "$KEY_PATH.pub"
log_success "Identity and signing key configured"

# ── allowed_signers for local verification ────────────────────────────────────
ALLOWED_SIGNERS="$SSH_DIR/allowed_signers"
PUBKEY_LINE="$GIT_EMAIL $(cat "$KEY_PATH.pub")"

# Remove any existing line for this email, then append the current entry
if [[ -f "$ALLOWED_SIGNERS" ]]; then
  grep -v "^$GIT_EMAIL " "$ALLOWED_SIGNERS" > "${ALLOWED_SIGNERS}.tmp" || true
  mv "${ALLOWED_SIGNERS}.tmp" "$ALLOWED_SIGNERS"
fi
echo "$PUBKEY_LINE" >> "$ALLOWED_SIGNERS"
chmod 600 "$ALLOWED_SIGNERS"

git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS"
log_success "~/.ssh/allowed_signers configured for local commit verification"

# ── lfs (per-user, idempotent) ────────────────────────────────────────────────
git lfs install
log_success "git-lfs initialized (per-user)"

# ── Optional: upload signing key to GitHub ────────────────────────────────────
if gh auth status &>/dev/null; then
  if prompt_yes_no "Upload id_git as a GitHub signing key now?" "y"; then
    _key_title="id_git ($(hostname))"
    upload_signing_key() {
      gh api -X POST /user/ssh_signing_keys \
        -f "title=$_key_title" \
        -f "key=$(cat "$KEY_PATH.pub")"
    }
    try_run "Upload signing key to GitHub" upload_signing_key
  fi
fi

# ── Display the public key + instructions ─────────────────────────────────────
log_section "New SSH signing key: $KEY_PATH.pub"
cat "$KEY_PATH.pub"
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Add this key to GitHub to mark your commits as Verified:"
log_info "  https://github.com/settings/ssh/new"
log_info ""
log_info "  Key type : Signing Key"
log_info "  Title    : id_git (or any label you prefer)"
log_info "  Key      : (paste the line above)"
log_info ""
log_info "Optionally add it as an Authentication Key too if you want to use"
log_info "this key for git push over SSH."
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_success "Git module completed successfully!"
