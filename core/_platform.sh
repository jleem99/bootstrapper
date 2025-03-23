#!/bin/bash
set -eu

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

# Function to check if the platform is supported for a module
# Usage: check_platform_supported "debian" "fedora" "macos"
check_platform_supported() {
  local supported=false
  for p in "$@"; do
    if [[ "$PLATFORM" == "$p" ]]; then
      supported=true
      break
    fi
  done
  
  if [[ "$supported" == "false" ]]; then
    log_error "This module is not supported on $PLATFORM"
    exit 1
  fi
}

# Function to run a platform-specific implementation
# Usage: run_platform_module "module_name"
# Example: run_platform_module "ssh-server"
run_platform_module() {
  local module_name="$1"
  shift  # Remove module name from arguments
  
  # Get calling script's directory
  local caller_dir="$(dirname "${BASH_SOURCE[1]}")"
  local module_dir=""
  
  # Determine the module directory
  if [[ "$caller_dir" == *"/modules/$module_name" ]]; then
    # Called from module/module.sh
    module_dir="$caller_dir"
  else
    # Called from somewhere else, construct the path
    module_dir="$BOOTSTRAPPER_ROOT/modules/$module_name"
  fi
  
  # Construct the platform script path
  local platform_script="$module_dir/$PLATFORM.sh"
  
  if [[ -f "$platform_script" ]]; then
    log_info "Running platform-specific implementation for $PLATFORM..."
    # Pass any additional arguments to the platform script
    source "$platform_script" "$@"
    log_success "✅ Platform-specific implementation completed"
    return 0
  else
    log_error "No platform-specific implementation found for $PLATFORM"
    log_error "Expected file: $platform_script"
    exit 1
  fi
}

# Export variables and functions
export PLATFORM
export PLATFORM_FAMILY
export PACKAGE_MANAGER
export -f check_platform_supported
export -f run_platform_module
export -f ensure_homebrew

# Detect platform at source time
detect_platform 