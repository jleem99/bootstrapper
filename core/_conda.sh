#!/bin/bash
set -eu

# Function to create a standard conda configuration
# Usage: create_conda_config
create_conda_config() {
  log_info "Creating conda configuration..."
  # Ensure .condarc exists with some sensible defaults
  cat > "${HOME}/.condarc" << EOF
channels:
  - conda-forge
  - defaults
auto_activate_base: false
changeps1: true
EOF
  log_success "Conda configuration created"
}

# Function to initialize conda for the current shell
# Usage: init_conda [conda_base_path]
init_conda() {
  local conda_base="${1:-$HOME/miniconda3}"
  
  log_info "Initializing Conda..."
  if [[ -f "$conda_base/bin/conda" ]]; then
    "$conda_base/bin/conda" init "$(basename "${SHELL}")"
    log_success "Conda initialized for $(basename "${SHELL}")"
  else
    log_error "Conda binary not found at $conda_base/bin/conda"
    return 1
  fi
}

# Function to install miniconda
# Usage: install_miniconda
install_miniconda() {
  # If Miniconda is already installed, skip
  if command -v conda &> /dev/null; then
    log_success "Conda is already installed!"
    log_info "Current conda version: $(conda --version)"
    return 0
  fi

  if [[ "$PLATFORM" == "macos" ]]; then
    # macOS - use Homebrew
    log_info "Installing Miniconda via Homebrew..."
    update_package_manager
    install_packages --cask miniconda
    CONDA_BASE=$(brew --prefix miniconda)
    init_conda "$CONDA_BASE"
  else
    # Linux platforms - download and install
    log_info "Downloading Miniconda installer..."
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    MINICONDA_INSTALLER="/tmp/miniconda.sh"
    wget -q -O "$MINICONDA_INSTALLER" "$MINICONDA_URL"
    
    log_info "Installing Miniconda..."
    bash "$MINICONDA_INSTALLER" -b -p "$HOME/miniconda3"
    
    # Initialize
    init_conda "$HOME/miniconda3"
    
    # Remove installer
    rm -f "$MINICONDA_INSTALLER"
  fi
  
  # Create standard config
  create_conda_config
  
  log_info "To use conda in the current session, run 'source ~/.bashrc' or restart your terminal"
  log_info "Use 'conda activate' to activate the base environment"
  
  return 0
}

# Export functions
export -f create_conda_config
export -f init_conda
export -f install_miniconda