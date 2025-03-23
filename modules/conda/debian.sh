#!/bin/bash
set -eu

log_info "Installing Conda for Debian/Ubuntu"

ensure_packages_installed "wget"

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

export PREFIX="$HOME/miniconda3"

bash Miniconda3-latest-Linux-x86_64.sh

# Initialize Conda for the current shell
log_info "Initializing Conda..."
CONDA_BASE="$HOME/miniconda3"  # Adjust this path if Miniconda is installed elsewhere

# Add conda initialization to the current shell
"$CONDA_BASE/bin/conda" init "$(basename "${SHELL}")"

# Activate Conda for the current shell
source "$CONDA_BASE/bin/activate"

log_success "Conda installed successfully!"
