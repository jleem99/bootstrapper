#!/bin/bash
set -euo pipefail

log_info "Installing Conda for macOS"

ensure_packages_installed "curl"

TEMP_DIR=$(mktemp -d)

curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -O "$TEMP_DIR/Miniconda3-latest-MacOSX-arm64.sh"

export PREFIX="$HOME/miniconda3"

bash "$TEMP_DIR/Miniconda3-latest-MacOSX-arm64.sh"

# Initialize Conda for the current shell
echo "Initializing Conda..."

# # Add conda initialization to the current shell
# "$PREFIX/bin/conda" init "$(basename "${SHELL}")"

# Activate Conda for the current shell
source "$PREFIX/bin/activate"

log_success "Conda installed successfully!"
