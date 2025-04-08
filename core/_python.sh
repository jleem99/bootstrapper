#!/bin/bash
set -euo pipefail

# Install pip packages
# Usage: install_pip_packages pkg1 pkg2 pkg3 ...
install_pip_packages() {
  if [ $# -eq 0 ]; then
    log_warning "No packages specified for installation"
    return 0
  fi
  
  local packages=("$@")
  log_info "Installing Python packages: ${packages[*]}"
  
  # Ensure pip is up to date
  python3 -m pip install --upgrade pip
  
  # Install packages
  python3 -m pip install "${packages[@]}"
  
  log_success "Python packages installed successfully"
  return 0
}

# Export functions
export -f install_pip_packages 