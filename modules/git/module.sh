#!/bin/bash
# Description: Configure git with aliases, SSH commit signing + auth, and GitHub identity
# Platforms: debian fedora rhel arch macos
set -euo pipefail

log_info "Running git module..."

# ── Prerequisites ──────────────────────────────────────────────────────────────
ensure_packages_installed git git-lfs

# ── GitHub CLI: install + authenticate ────────────────────────────────────────
run_module "gh"
export GH_PAGER=

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

# ── SSH config: use id_git for github.com (auth + signing) ───────────────────
SSH_CONFIG="$SSH_DIR/config"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

SSH_BLOCK="# >>> bootstrapper >>>
Host github.com
  HostName github.com
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
# <<< bootstrapper <<<"

write_managed_block "$SSH_CONFIG" "$SSH_BLOCK"
log_success "~/.ssh/config: github.com → id_git"

# ── Optional: upload keys to GitHub ──────────────────────────────────────────
if gh auth status &>/dev/null; then
  if prompt_yes_no "Upload id_git to GitHub (signing + auth key)?" "y"; then
    _key_title="id_git ($(hostname))"
    _pubkey="$(cat "$KEY_PATH.pub")"

    upload_signing_key() {
      gh api -X POST /user/ssh_signing_keys \
        -f "title=$_key_title" \
        -f "key=$_pubkey"
    }
    upload_auth_key() {
      gh api -X POST /user/keys \
        -f "title=$_key_title" \
        -f "key=$_pubkey"
    }

    try_run "Upload signing key to GitHub" upload_signing_key
    try_run "Upload authentication key to GitHub" upload_auth_key
  fi
fi

log_info "Public key: cat $KEY_PATH.pub"
log_success "Git module completed successfully!"
