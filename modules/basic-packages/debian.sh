#!/bin/bash
set -eu

log_info "Installing basic packages for Debian/Ubuntu..."

# Update package lists
update_package_manager

# Install basic packages
log_info "Installing system packages..."
install_packages \
  git \
  wget \
  curl \
  tmux \
  neovim \
  htop

# Install dua-cli
curl -LSfs https://raw.githubusercontent.com/Byron/dua-cli/master/ci/install.sh | \
    sh -s -- --git Byron/dua-cli --target x86_64-unknown-linux-musl --crate dua --tag v2.29.0

# Add dua-cli to PATH
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> $(get_shell_profile)
source $(get_shell_profile)
