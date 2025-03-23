#!/bin/bash
set -eu

log_info "Installing basic packages for macOS..."

# Update Homebrew
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