#!/bin/bash
set -euo pipefail

# Function to update the package manager
# Usage: update_package_manager
update_package_manager() {
  log_info "Updating package manager..."

  if [[ "$PLATFORM" == "macos" ]]; then
    ensure_homebrew
  fi
  
  case "$PACKAGE_MANAGER" in
    "apt")
      sudo apt-get update
      ;;
    "dnf")
      sudo dnf check-update || true  # dnf returns non-zero exit code if updates are available
      ;;
    "yum")
      sudo yum check-update || true  # yum returns non-zero exit code if updates are available
      ;;
    "pacman")
      sudo pacman -Sy --noconfirm
      ;;
    "brew")
      brew update
      ;;
    *)
      log_warning "Unknown package manager: $PACKAGE_MANAGER"
      return 1
      ;;
  esac
  
  log_success "Package manager updated successfully"
  return 0
}

# Function to upgrade all packages
# Usage: upgrade_system
upgrade_system() {
  log_info "Upgrading system packages..."

  if [[ "$PLATFORM" == "macos" ]]; then
    ensure_homebrew
  fi
  
  case "$PACKAGE_MANAGER" in
    "apt")
      sudo apt-get upgrade -y
      ;;
    "dnf")
      sudo dnf upgrade -y
      ;;
    "yum")
      sudo yum upgrade -y
      ;;
    "pacman")
      sudo pacman -Syu --noconfirm
      ;;
    "brew")
      brew upgrade
      ;;
    *)
      log_warning "Unknown package manager: $PACKAGE_MANAGER"
      return 1
      ;;
  esac
  
  log_success "System packages upgraded successfully"
  return 0
}

# Function to install packages with the platform-specific package manager
# Usage: install_packages pkg1 pkg2 pkg3 ...
install_packages() {
  if [ $# -eq 0 ]; then
    log_warning "No packages specified for installation"
    return 0
  fi
  
  local packages=("$@")
  log_info "Installing packages: ${packages[*]}"
  
  case "$PACKAGE_MANAGER" in
    "apt")
      sudo apt-get install -y "${packages[@]}"
      ;;
    "dnf")
      sudo dnf install -y "${packages[@]}"
      ;;
    "yum")
      sudo yum install -y "${packages[@]}"
      ;;
    "pacman")
      sudo pacman -S --noconfirm "${packages[@]}"
      ;;
    "brew")
      brew install "${packages[@]}"
      ;;
    *)
      log_warning "Unknown package manager: $PACKAGE_MANAGER"
      return 1
      ;;
  esac
  
  log_success "Packages installed successfully"
  return 0
}

# Function to check if a package is installed
# Usage: ensure_packages_installed "package1" "package2" "package3" ...
ensure_packages_installed() {
  local packages=("$@")
  for package in "${packages[@]}"; do
    if ! command -v "$package" &> /dev/null; then
      log_warning "Package $package is not installed, installing..."
      install_packages "$package"
    else
      log_success "Package $package is installed, proceeding..."
    fi
  done
}

# Export functions
export -f update_package_manager
export -f upgrade_system
export -f install_packages 
export -f ensure_packages_installed