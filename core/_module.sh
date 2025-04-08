#!/bin/bash
set -euo pipefail

# Function to check if a module is supported on the current platform
# This eliminates the need for each module to check platform support individually
# Usage: module_check_supported "module_name" "debian" "fedora" "macos"
module_check_supported() {
  local module_name="$1"
  shift
  
  local supported=false
  for p in "$@"; do
    if [[ "$PLATFORM" == "$p" ]]; then
      supported=true
      break
    fi
  done
  
  if [[ "$supported" == "false" ]]; then
    log_error "Module $module_name is not supported on $PLATFORM"
    exit 1
  fi
}

# Function to run a platform-specific module implementation
# Usage: module_run_platform "module_name" [extra_args]
module_run_platform() {
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
    # Called from somewhere else, use BOOTSTRAPPER_ROOT
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

# Export utility functions
export -f module_check_supported
export -f module_run_platform