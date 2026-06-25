#!/bin/bash
set -euo pipefail

# Platform detection module for bootstrapper
# This will be sourced by other modules to detect the platform and package manager

# Define platform variables
PLATFORM=""
PLATFORM_FAMILY=""
PACKAGE_MANAGER=""

# Function to detect the platform
detect_platform() {
  # Detect OS type
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM_FAMILY="linux"

    # Detect Linux distribution and package manager
    if command -v apt-get &> /dev/null; then
      PLATFORM="debian"
      PACKAGE_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
      PLATFORM="fedora"
      PACKAGE_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
      PLATFORM="rhel"
      PACKAGE_MANAGER="yum"
    elif command -v pacman &> /dev/null; then
      PLATFORM="arch"
      PACKAGE_MANAGER="pacman"
    else
      log_warning "Unsupported Linux distribution"
      PLATFORM="unknown"
      PACKAGE_MANAGER="unknown"
    fi

  elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    PLATFORM_FAMILY="darwin"

    # Check if Homebrew is installed
    if command -v brew &> /dev/null; then
      PACKAGE_MANAGER="brew"
    else
      PACKAGE_MANAGER="none"
    fi

  else
    log_warning "Unsupported operating system: $OSTYPE"
    PLATFORM="unknown"
    PLATFORM_FAMILY="unknown"
    PACKAGE_MANAGER="unknown"
  fi
}

# Function to install homebrew on macOS if needed
ensure_homebrew() {
  if [[ "$PLATFORM" == "macos" && "$PACKAGE_MANAGER" == "none" ]]; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    PACKAGE_MANAGER="brew"
  fi
}

# Export variables and functions
export PLATFORM
export PLATFORM_FAMILY
export PACKAGE_MANAGER
export -f ensure_homebrew

# Detect platform at source time
detect_platform

# Dynamic sudo override for gcsudo environments (NHN Cloud GPU instances)
if [[ -f "/engrid/ensh/gpubin/ctn_gcsudo" ]]; then
  sudo() {
    /engrid/ensh/gpubin/ctn_gcsudo "$@"
  }
  export -f sudo
fi
